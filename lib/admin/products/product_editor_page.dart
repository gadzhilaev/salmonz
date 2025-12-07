import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;
const String _bucket = 'Menu'; // <- по твоим скринам с файлами

class ProductEditorPage extends StatefulWidget {
  const ProductEditorPage({super.key, this.existing});
  final dynamic existing; // _ProdItem
  @override
  State<ProductEditorPage> createState() => _ProductEditorPageState();
}

class _ProductEditorPageState extends State<ProductEditorPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;

  final _nameCtrl = TextEditingController();
  final _grammCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _imgUrl;
  String? _type; // категория (type из products)
  bool _inStock = true; // наличие

  List<_Cat> _cats = [];

  Future<void> _ensureAuth() async {
    if (supa.auth.currentSession == null) {
      try {
        await supa.auth.signInAnonymously();
      } catch (_) {}
    }
  }

  Future<void> _loadCats() async {
    final res = await supa.from('categories').select('type,title').order('position');

    String cap(String s) =>
        s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

    final byKey = <String, _Cat>{};
    for (final e in (res as List)) {
      final rawType  = (e['type']  ?? '').toString().trim();
      final rawTitle = (e['title'] ?? '').toString();
      final key = rawType.toLowerCase();
      byKey.putIfAbsent(key, () => _Cat(
        type: rawType,      // значение в БД (как есть, но без пробелов по краям)
        title: cap(rawTitle),
      ));
    }
    final cats = byKey.values.toList();

    String? fixedType;
    if (_type != null && _type!.trim().isNotEmpty) {
      final keyWanted = _type!.trim().toLowerCase();
      final match = cats.firstWhere(
            (c) => c.type.toLowerCase() == keyWanted,
        orElse: () => _Cat(type: '', title: ''),
      );
      fixedType = match.type.isEmpty ? null : match.type;
    }

    setState(() {
      _cats = cats;
      _type = fixedType;
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureAuth();
    _loadCats();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _grammCtrl.text = e.gramm.toString();
      _amountCtrl.text = e.amount.toString();
      _descCtrl.text = e.description;
      _priceCtrl.text = e.price.toString();
      _imgUrl = e.img;
      _type = e.type;
      _inStock = e.isStock;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _grammCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt =
          (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) ? ext : 'jpg';
      final path = 'prod_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      await supa.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions:
                FileOptions(contentType: 'image/$safeExt', upsert: true),
          );
      final url = supa.storage.from(_bucket).getPublicUrl(path);
      setState(() => _imgUrl = url);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Изображение загружено')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  Future<void> _deleteProduct() async {
    final e = widget.existing;
    if (e == null) return;
    try {
      await supa.from('products').delete().eq('id', e.id);
      // попытаться удалить файл
      final url = e.img as String;
      final pref = '/object/public/$_bucket/';
      final idx = url.indexOf(pref);
      if (idx != -1) {
        final path = url.substring(idx + pref.length);
        try {
          await supa.storage.from(_bucket).remove([path]);
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final gramm = int.tryParse(_grammCtrl.text.trim()) ?? 0;
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final desc = _descCtrl.text.trim();
    final price =
        double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final img = _imgUrl ?? '';
    final type = _type ?? '';

    if (name.isEmpty || img.isEmpty || type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Заполните название, категорию и загрузите картинку')),
      );
      return;
    }

    final payload = {
      'name': name,
      'img': img,
      'description': desc,
      'gramm': gramm,
      'amount': amount,
      'price': price,
      'type': type,
      'is_stock': _inStock,
    };

    try {
      final res = (widget.existing == null)
          ? await supa.from('products').insert(payload).select()
          : await supa.from('products').update(payload)
          .eq('id', widget.existing.id)
          .select();

      if (res.isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // ничего не вернулось — значит ничего не изменили (RLS/eq не совпал)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить (проверьте права RLS и ID)')),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: ${e.message}')),
      );
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
                // --- appbar как было ---
                SizedBox(
                  height: hLogo + 26,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        left: 20,
                        top: 26,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 20, color: arrowColor),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        child: Image.asset('assets/icon/logo_salmonz_small.png',
                            width: 80, height: 62, fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),

                // 👇 ВЕСЬ НИЖНИЙ КОНТЕНТ — ПРОКРУЧИВАЕМЫЙ
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom +
                          24, // чтобы не упиралось в клавиатуру
                    ),
                    children: [
                      // --- картинка + плюс/удалить ---
                      SizedBox(
                        width: double.infinity,
                        height: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: const Color(0xFFF1F1F1)),
                              if (_imgUrl == null || _imgUrl!.isEmpty)
                                const _UploadHint(
                                    text: 'ЗАГРУЗИТЕ  КАРТИНКУ ТОВАРА')
                              else
                                Image.network(_imgUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const _UploadHint(
                                            text:
                                                'ЗАГРУЗИТЕ  КАРТИНКУ ТОВАРА')),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: RawMaterialButton(
                                    onPressed: isEdit
                                        ? _deleteProduct
                                        : _pickAndUpload,
                                    fillColor: orange,
                                    shape: const CircleBorder(),
                                    elevation: 0,
                                    child: Icon(
                                        isEdit ? Icons.delete : Icons.add,
                                        size: 24,
                                        color: const Color(0xFFE8EAED)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- поля ---
                      const _FieldLabel('Название'),
                      _RoundedField(
                          controller: _nameCtrl, hint: 'Введите название'),
                      const SizedBox(height: 16),

                      const _FieldLabel('Колво грамм'),
                      _RoundedField(
                          controller: _grammCtrl,
                          hint: 'Например: 270',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),

                      const _FieldLabel('Колво штук'),
                      _RoundedField(
                          controller: _amountCtrl,
                          hint: 'Например: 8',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),

                      const _FieldLabel('Состав'),
                      _RoundedField(
                          controller: _descCtrl, hint: 'Описание/состав'),
                      const SizedBox(height: 16),

                      const _FieldLabel('Цена'),
                      _RoundedField(
                          controller: _priceCtrl,
                          hint: 'Например: 399',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),

                      const _FieldLabel('Категория'),
                      _DropdownField<String>(
                        value: _type,
                        hint: 'Выберите категорию',
                        trailingArrow: true,
                        items: _cats
                            .map((c) => DropdownMenuItem(
                                value: c.type, child: Text(c.title)))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Наличие'),
                      _DropdownField<bool>(
                        value: _inStock,
                        hint: 'Выберите наличие',
                        trailingArrow: true,
                        items: const [
                          DropdownMenuItem(
                              value: true, child: Text('Есть в наличии')),
                          DropdownMenuItem(
                              value: false, child: Text('Нет в наличии')),
                        ],
                        onChanged: (v) => setState(() => _inStock = v ?? true),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40)),
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              elevation: 0,
                            ),
                            child: const Text('СОХРАНИТЬ',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

/* ------------------------ helpers ------------------------ */

class _UploadHint extends StatelessWidget {
  const _UploadHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 51),
          Image.asset('assets/promotions/Vector.png',
              width: 80, height: 80, fit: BoxFit.contain),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black)),
          const SizedBox(height: 8),
          const Text('Формат: JPG, GIF, PNG.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 12, color: Color(0xFF989EA2))),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 13,
          height: 1.0,
          color: Color(0xB2464646), // #464646B2
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({required this.controller, this.hint, this.keyboardType});
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              fontFamily: 'Inter', fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.trailingArrow = false,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String hint;
  final bool trailingArrow;

  void _showNativePicker(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      // iOS: CupertinoPicker в bottom sheet
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SizedBox(
            height: 250,
            child: CupertinoPicker(
              backgroundColor: Colors.white,
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: items.indexWhere((e) => e.value == value),
              ),
              onSelectedItemChanged: (index) {
                onChanged(items[index].value);
              },
              children: items.map((e) => Center(child: e.child)).toList(),
            ),
          );
        },
      );
    } else {
      // Android: показываем стандартный список
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return ListView(
            shrinkWrap: true,
            children: items.map((e) {
              return ListTile(
                title: e.child,
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(e.value);
                },
              );
            }).toList(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = items.cast<DropdownMenuItem<T>?>().firstWhere(
          (e) => e?.value == value,
      orElse: () => null,
    );
    final currentLabel = match?.child ?? Text(hint);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _showNativePicker(context),
        borderRadius: BorderRadius.circular(10000),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF5E1C), width: 1),
            borderRadius: BorderRadius.circular(10000),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.black,
                ),
                child: currentLabel,
              ),
              if (trailingArrow)
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Color(0xFFFF5E1C), // 👈 твой цвет
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cat {
  _Cat({required this.type, required this.title});
  final String type;
  final String title;
}
