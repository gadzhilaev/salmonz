import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salmonz/utils/category.dart';

final supa = Supabase.instance.client;
const String _bucket = 'categories_imgs';

class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({super.key, this.existing});
  final CategoryItem? existing; // <— здесь CategoryItem, не _CatItem
  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const orange = Color(0xFFFF5E1C);

  static const double hLogo = 62;

  final _titleCtrl = TextEditingController();
  final _typeCtrl  = TextEditingController();
  final _posCtrl   = TextEditingController();

  String? _imgUrl;

  Future<void> _ensureAuth() async {
    if (supa.auth.currentSession == null) {
      try { await supa.auth.signInAnonymously(); } catch (_) {}
    }
  }

  Future<void> _deleteCategory() async {
    if (widget.existing == null) return;

    try {
      // 1) Удаляем строку и проверяем, что затронута хотя бы 1 запись
      final deleted = await supa
          .from('categories')
          .delete()
          .eq('id', widget.existing!.id)
          .select(); // вернёт удалённые строки (если политика SELECT на delete разрешена)

      if (deleted.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить запись (RLS или ограничения БД)')),
        );
        return;
      }

      // 2) Пытаемся удалить файл из Storage (не критично, если не получится)
      final url = widget.existing!.img;
      final prefix = '/object/public/$_bucket/';
      final idx = url.indexOf(prefix);
      if (idx != -1) {
        final path = url.substring(idx + prefix.length);
        try { await supa.storage.from(_bucket).remove([path]); } catch (_) {}
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureAuth();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _typeCtrl.text  = widget.existing!.type;
      _posCtrl.text   = widget.existing!.position.toString();
      _imgUrl         = widget.existing!.img;   // <—
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _typeCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = (['jpg','jpeg','png','gif'].contains(ext)) ? ext : 'jpg';
      final path = 'cat_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

      // используем bucket 'categories' (создайте его в Supabase Storage)
      await supa.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$safeExt', upsert: true),
      );

      final publicUrl = supa.storage.from(_bucket).getPublicUrl(path);
      setState(() => _imgUrl = publicUrl);

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

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final type  = _typeCtrl.text.trim();
    final pos   = int.tryParse(_posCtrl.text.trim()) ?? 0;
    final img   = _imgUrl ?? '';

    if (title.isEmpty || type.isEmpty || img.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните название, английское название и загрузите картинку')),
      );
      return;
    }

    try {
      if (widget.existing == null) {
        await supa.from('categories').insert({
          'title': title,
          'type':  type,
          'img':   img,
          'position': pos,
        });
      } else {
        await supa.from('categories').update({
          'title': title,
          'type':  type,
          'img':   img,
          'position': pos,
        }).eq('id', widget.existing!.id);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
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
              // appbar
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

              // Малый контейнер 369x260 с внутренним FAB (12,12)
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // фон/картинка
                        Container(
                          color: const Color(0xFFF1F1F1),
                          child: (_imgUrl == null || _imgUrl!.isEmpty)
                              ? const _EmptyPickerCategory()
                              : Image.network(
                            _imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _EmptyPickerCategory(),
                          ),
                        ),
                        // внутренняя круглая кнопка — теперь точно "внутри" контейнера
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: SizedBox(
                            width: 60, height: 60,
                            child: RawMaterialButton(
                              onPressed: isEdit ? _deleteCategory : _pickAndUpload,
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
              ),

              const SizedBox(height: 24),

              // Название
              const Padding(
                padding: EdgeInsets.only(left: 24),
                child: Text(
                  'Название',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.0,
                    color: Color(0xB2464646), // #464646B2
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _RoundedField(controller: _titleCtrl, hint: 'Введите название'),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.only(left: 24),
                child: Text(
                  'Название на английском',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.0,
                    color: Color(0xB2464646),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _RoundedField(controller: _typeCtrl, hint: 'Например: rolls'),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.only(left: 24),
                child: Text(
                  'Позиция',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.0,
                    color: Color(0xB2464646),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _RoundedField(
                controller: _posCtrl,
                hint: 'Например: 1',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------- helpers ---------------------------------- */

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // чтобы ширина ~361
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint ?? '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10000),
              borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10000),
              borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10000),
              borderSide: const BorderSide(color: Color(0xFFFF5E1C), width: 2),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.0,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// серый контейнер-заглушка для категории (высота 260, внутренние отступы как по ТЗ)
class _EmptyPickerCategory extends StatelessWidget {
  const _EmptyPickerCategory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 51),
          // иконка 80×80
          _VectorIcon(),
          SizedBox(height: 14),
          Text(
            'ЗАГРУЗИТЕ КАРТИНКУ КАТЕГОРИИ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.5,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
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
        ],
      ),
    );
  }
}

class _VectorIcon extends StatelessWidget {
  const _VectorIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/promotions/Vector.png', // как просили
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
  }
}