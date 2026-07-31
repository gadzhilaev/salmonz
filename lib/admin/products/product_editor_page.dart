import 'package:flutter/material.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/widgets/app_error_view.dart';

class ProductEditorPage extends StatefulWidget {
  const ProductEditorPage({super.key, this.existing});
  final ProductModel? existing;

  @override
  State<ProductEditorPage> createState() => _ProductEditorPageState();
}

class _ProductEditorPageState extends State<ProductEditorPage> {
  static const orange = Color(0xFFFF5E1C);

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String? _imageKey;
  String? _imageUrl;
  String? _categoryId;
  bool _inStock = true;
  bool _saving = false;
  bool _catsLoading = true;
  Object? _catsError;
  List<CategoryModel> _cats = [];

  @override
  void initState() {
    super.initState();
    _loadCats();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _priceCtrl.text = e.price.asDouble.toString();
      _weightCtrl.text = (e.weight ?? 0).toString();
      _imageKey = e.imageKey;
      _imageUrl = e.imageUrl;
      _categoryId = e.categoryId;
      _inStock = e.isAvailable;
    }
  }

  Future<void> _loadCats() async {
    setState(() {
      _catsLoading = true;
      _catsError = null;
    });
    try {
      final cats = await AppServices.instance.admin.listCategories(limit: 100);
      if (!mounted) return;
      setState(() {
        _cats = cats;
        if (_categoryId == null && cats.isNotEmpty) {
          _categoryId = cats.first.id;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _catsError = e);
    } finally {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    try {
      final up = await AppServices.instance.admin.uploadProductImage(
        filePath: picked.path,
        filename: p.basename(picked.path),
      );
      setState(() {
        _imageKey = up.key;
        _imageUrl = up.url;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.userMessage)));
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    try {
      await AppServices.instance.admin.deleteProduct(e.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.userMessage)));
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price =
        double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final weight = int.tryParse(_weightCtrl.text.trim());
    if (name.isEmpty || _categoryId == null || _imageKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните название, категорию и картинку'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'categoryId': _categoryId,
        'name': name,
        'description': _descCtrl.text.trim(),
        'price': price,
        'imageKey': _imageKey,
        if (weight != null) 'weight': weight,
        'isAvailable': _inStock,
      };
      if (widget.existing == null) {
        await AppServices.instance.admin.createProduct(body);
      } else {
        await AppServices.instance.admin.updateProduct(
          widget.existing!.id,
          body,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.userMessage)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Новый товар' : 'Товар'),
        actions: [
          if (widget.existing != null)
            Semantics(
              identifier: 'productDeleteButton',
              button: true,
              label: 'Удалить',
              child: IconButton(
                key: const Key('productDeleteButton'),
                onPressed: _delete,
                icon: const Icon(Icons.delete),
              ),
            ),
        ],
      ),
      body: _catsError != null
          ? Center(
              child: AppErrorView(
                message: ApiException.userMessageFrom(_catsError!),
                onRetry: _loadCats,
              ),
            )
          : _catsLoading
          ? const Center(child: CircularProgressIndicator())
          : AppPageContainer.form(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Semantics(
                    identifier: 'productNameField',
                    textField: true,
                    child: TextField(
                      key: const Key('productNameField'),
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                  ),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    maxLines: 3,
                  ),
                  Semantics(
                    identifier: 'productPriceField',
                    textField: true,
                    child: TextField(
                      key: const Key('productPriceField'),
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Цена'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  TextField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(labelText: 'Вес (г)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    items: _cats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    decoration: const InputDecoration(labelText: 'Категория'),
                  ),
                  SwitchListTile(
                    title: const Text('В наличии'),
                    value: _inStock,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                  if ((_imageUrl ?? '').isNotEmpty)
                    Image.network(_imageUrl!, height: 160, fit: BoxFit.cover),
                  Semantics(
                    identifier: 'productUploadImage',
                    button: true,
                    child: TextButton.icon(
                      key: const Key('productUploadImage'),
                      onPressed: _pickAndUpload,
                      icon: const Icon(Icons.upload),
                      label: const Text('Загрузить фото'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: 'productSaveButton',
                    button: true,
                    child: ElevatedButton(
                      key: const Key('productSaveButton'),
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: orange),
                      child: const Text(
                        'СОХРАНИТЬ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
