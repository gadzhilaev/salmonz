import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/widgets/app_error_view.dart';

class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  late Future<List<SupportMessageModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.listSupport(limit: 100);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.admin.listSupport(limit: 100);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обращения', key: Key('adminSupportTitle')),
      ),
      body: AppPageContainer(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<SupportMessageModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      child: AppErrorView(
                        message: ApiException.userMessageFrom(snap.error!),
                        onRetry: _reload,
                      ),
                    ),
                  ],
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Обращений пока нет')),
                  ],
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = items[i];
                  return ListTile(
                    key: Key('adminSupportItem_${m.id}'),
                    title: Text(
                      m.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if ((m.userEmail ?? '').isNotEmpty) m.userEmail!,
                        if ((m.userName ?? '').isNotEmpty) m.userName!,
                        m.status,
                      ].where((e) => e.trim().isNotEmpty).join(' · '),
                    ),
                    onTap: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Обращение'),
                          content: SingleChildScrollView(
                            child: SelectableText(
                              '${m.message}\n\n'
                              'От: ${m.userName ?? ''} <${m.userEmail ?? ''}>\n'
                              'Статус: ${m.status}',
                              key: const Key('adminSupportDetailBody'),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Закрыть'),
                            ),
                            if (m.status.toUpperCase() != 'CLOSED')
                              TextButton(
                                key: const Key('adminSupportClose'),
                                onPressed: () async {
                                  try {
                                    await AppServices.instance.admin
                                        .updateSupportStatus(m.id, 'CLOSED');
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _reload();
                                  } on ApiException catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.userMessage)),
                                    );
                                  }
                                },
                                child: const Text('Закрыть обращение'),
                              ),
                          ],
                        ),
                      );
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
