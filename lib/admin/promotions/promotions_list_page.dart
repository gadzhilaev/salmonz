import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';

class PromotionsListPage extends StatefulWidget {
  const PromotionsListPage({super.key});
  @override
  State<PromotionsListPage> createState() => _PromotionsListPageState();
}

class _PromotionsListPageState extends State<PromotionsListPage> {
  late Future<List<PromotionModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.listPromotions(limit: 100);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.admin.listPromotions(limit: 100);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Акции')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF5E1C),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PromotionEditorPage()),
          );
          if (ok == true) await _reload();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AppPageContainer(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<PromotionModel>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final promo = items[i];
                  return ListTile(
                    leading: (promo.imageUrl ?? '').isEmpty
                        ? null
                        : Image.network(
                            promo.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                    title: Text(promo.title),
                    onTap: () async {
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PromotionEditorPage(existing: promo),
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

class PromotionEditorPage extends StatefulWidget {
  const PromotionEditorPage({super.key, this.existing});
  final PromotionModel? existing;

  @override
  State<PromotionEditorPage> createState() => _PromotionEditorPageState();
}

class _PromotionEditorPageState extends State<PromotionEditorPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String? _imageKey;
  String? _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description ?? '';
      _imageKey = e.imageKey;
      _imageUrl = e.imageUrl;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final up = await AppServices.instance.admin.uploadPromotionImage(
      filePath: picked.path,
      filename: p.basename(picked.path),
    );
    setState(() {
      _imageKey = up.key;
      _imageUrl = up.url;
    });
  }

  Future<void> _save() async {
    if ((_imageKey ?? '').isEmpty || _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нужны заголовок и изображение')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'imageKey': _imageKey,
        'isActive': true,
      };
      if (widget.existing == null) {
        await AppServices.instance.admin.createPromotion(body);
      } else {
        await AppServices.instance.admin.updatePromotion(
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
    await AppServices.instance.admin.deletePromotion(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Новая акция' : 'Акция'),
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
              controller: _title,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
            ),
            if ((_imageUrl ?? '').isNotEmpty)
              Image.network(_imageUrl!, height: 160, fit: BoxFit.cover),
            TextButton(onPressed: _upload, child: const Text('Загрузить фото')),
            ElevatedButton(
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
