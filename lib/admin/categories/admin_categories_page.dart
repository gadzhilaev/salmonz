import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});
  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  late Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.listCategories(limit: 100);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.admin.listCategories(limit: 100);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Категории')),
      floatingActionButton: FloatingActionButton(
        key: const Key('adminCategoriesAdd'),
        backgroundColor: const Color(0xFFFF5E1C),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CategoryEditorPage()),
          );
          if (ok == true) await _reload();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AppPageContainer(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<CategoryModel>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final c = items[i];
                  return ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.slug),
                    onTap: () async {
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryEditorPage(existing: c),
                        ),
                      );
                      if (ok == true) await _reload();
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({super.key, this.existing});
  final CategoryModel? existing;

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  String? _imageKey;
  String? _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _slug.text = e.slug;
      _imageKey = e.imageKey;
      _imageUrl = e.imageUrl;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final up = await AppServices.instance.admin.uploadCategoryImage(
      filePath: picked.path,
      filename: p.basename(picked.path),
    );
    setState(() {
      _imageKey = up.key;
      _imageUrl = up.url;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'slug': _slug.text.trim(),
        if (_imageKey != null) 'imageKey': _imageKey,
      };
      if (widget.existing == null) {
        await AppServices.instance.admin.createCategory(body);
      } else {
        await AppServices.instance.admin.updateCategory(
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
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await AppServices.instance.admin.deleteCategory(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Новая категория' : 'Категория'),
        actions: [
          if (widget.existing != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: AppPageContainer.form(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            TextField(
              key: const Key('categoryNameField'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              key: const Key('categorySlugField'),
              controller: _slug,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
            if ((_imageUrl ?? '').isNotEmpty)
              Image.network(_imageUrl!, height: 120, fit: BoxFit.cover),
            TextButton(onPressed: _upload, child: const Text('Загрузить фото')),
            ElevatedButton(
              key: const Key('categorySaveButton'),
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E1C),
              ),
              child: const Text(
                'СОХРАНИТЬ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
