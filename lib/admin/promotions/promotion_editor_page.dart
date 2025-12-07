import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';     // 👈 выбор фото/файла
import '../../utils/promo.dart';

final supa = Supabase.instance.client;

class PromotionEditorPage extends StatefulWidget {
  const PromotionEditorPage({super.key, this.existing});
  final Promo? existing;

  @override
  State<PromotionEditorPage> createState() => _PromotionEditorPageState();
}

class _PromotionEditorPageState extends State<PromotionEditorPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const orange = Color(0xFFFF5E1C);

  static const double hLogo = 62;

  String? _imgUrl;              // публичный URL картинки (Storage)

  @override
  void initState() {
    super.initState();
    _imgUrl = widget.existing?.img;
    _ensureAuth();
  }

  Future<void> _ensureAuth() async {
    if (supa.auth.currentSession == null) {
      try {
        await supa.auth.signInAnonymously(); // потребуется актуальная supabase_flutter
      } catch (_) {
        // fallback: ничего
      }
    }
  }

  // === ВЫБОР ФАЙЛА + ЗАЛИВКА В STORAGE ===
  Future<void> _pickAndUpload() async {
    await _ensureAuth();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();          // Uint8List
      final fileName = picked.name;                      // напр. IMG_1234.jpg
      final ext = fileName.split('.').last.toLowerCase();
      final safeExt = (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif') ? ext : 'jpg';

      // уникальный путь в бакете promotions
      final path = 'promo_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

      // upload to storage
      await supa.storage.from('promotions').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$safeExt',
          upsert: true,
        ),
      );

      // public url
      final publicUrl = supa.storage.from('promotions').getPublicUrl(path);

      setState(() {
        _imgUrl = publicUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изображение загружено')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  // === СОХРАНЕНИЕ В ТАБЛИЦУ promotions ===
  Future<void> _save() async {
    await _ensureAuth();
    final url = _imgUrl?.trim() ?? '';
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите изображение')),
      );
      return;
    }
    try {
      if (widget.existing == null) {
        await supa.from('promotions').insert({'img': url});
      } else {
        await supa.from('promotions').update({'img': url}).eq('id', widget.existing!.id);
      }
      if (!mounted) return;
      Navigator.pop(context, true); // вернуться к списку — Stream обновит экран
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  // === УДАЛЕНИЕ ЗАПИСИ ИЗ ТАБЛИЦЫ ===
  Future<void> _delete() async {
    await _ensureAuth();
    if (widget.existing == null) return;
    try {
      await supa.from('promotions').delete().eq('id', widget.existing!.id);

      // при желании можно попытаться удалить файл из storage,
      // если ты хранишь относительный путь. Здесь пропускаем.

      if (!mounted) return;
      Navigator.pop(context, true); // назад: стрим в списке сам обновится
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // APPBAR
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20, top: 26,
                      child: SizedBox(
                        width: 24, height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80, height: 62, fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // СЕРЫЙ/КАРТИННЫЙ БЛОК 369x554 + ВНУТРЕННЯЯ КНОПКА СПРАВА-НИЗ
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 554,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: const Color(0xFFF1F1F1),
                          child: _imgUrl == null || _imgUrl!.isEmpty
                              ? _EmptyPicker(onPick: _pickAndUpload)
                              : Image.network(
                            _imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _EmptyPicker(onPick: _pickAndUpload),
                          ),
                        ),
                      ),

                      // ВНУТРЕННЯЯ круглая кнопка — справа 24, снизу 40
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: SizedBox(
                          width: 60, height: 60,
                          child: RawMaterialButton(
                            onPressed: isEdit ? _delete : _pickAndUpload,
                            fillColor: orange,
                            shape: const CircleBorder(),
                            elevation: 0,
                            child: Icon(
                              isEdit ? Icons.delete : Icons.add,
                              size: 24,
                              color: const Color(0xFFE8EAED),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // КНОПКА СОХРАНИТЬ
              Center(
                child: SizedBox(
                  width: 353,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      elevation: 0,
                    ),
                    child: const Text(
                      'СОХРАНИТЬ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.0,
                        letterSpacing: 0.48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/promotions/Vector.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            'ЗАГРУЗИТЕ КАРТИНКУ АКЦИИ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Формат: JPG, GIF, PNG.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 14/12,
              letterSpacing: 0.25,
              color: Color(0xFF989EA2),
            ),
          ),
          const SizedBox(height: 16),
          // маленькая кнопка для выбора (дубль на случай ошибок загрузки)
        ],
      ),
    );
  }
}