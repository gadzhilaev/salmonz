import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/widgets/app_button.dart';
import 'package:salmonz/widgets/app_empty_state.dart';
import 'package:salmonz/widgets/app_error_view.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_notice.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  late Future<List<SupportMessageModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.support.list();
  }

  Future<void> _reload() async {
    setState(() => _future = AppServices.instance.support.list());
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _newTicket() async {
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Новое обращение'),
          content: TextField(
            controller: c,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Опишите вопрос'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );
    if (text == null || text.isEmpty) return;
    try {
      final created = await AppServices.instance.support.create(message: text);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportChatPage(ticketId: created.id),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      AppNotice.error(context, ApiException.userMessageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.nested(title: 'Поддержка'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Написать'),
      ),
      body: SafeArea(
        child: AppPageContainer(
          child: FutureBuilder<List<SupportMessageModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return AppErrorView(
                  message: ApiException.userMessageFrom(snap.error!),
                  onRetry: _reload,
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return AppEmptyState(
                  title: 'Обращений пока нет',
                  message: 'Напишите в поддержку — мы ответим здесь',
                  icon: Icons.forum_outlined,
                  actionLabel: 'Написать',
                  onAction: _newTicket,
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return Material(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadii.mdAll,
                      child: ListTile(
                        title: Text(
                          t.subject?.isNotEmpty == true
                              ? t.subject!
                              : t.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${t.status} · ${t.replies.length} ответов',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupportChatPage(ticketId: t.id),
                            ),
                          );
                          await _reload();
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key, required this.ticketId});
  final String ticketId;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  late Future<SupportMessageModel> _future;
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.support.get(widget.ticketId);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.support.get(widget.ticketId);
    });
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await AppServices.instance.support.reply(id: widget.ticketId, body: text);
      _input.clear();
      await _reload();
    } catch (e) {
      if (mounted) AppNotice.error(context, ApiException.userMessageFrom(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}.${d.month} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.nested(title: 'Переписка'),
      body: SafeArea(
        child: AppPageContainer(
          child: FutureBuilder<SupportMessageModel>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return AppErrorView(
                  message: ApiException.userMessageFrom(snap.error!),
                  onRetry: _reload,
                );
              }
              final ticket = snap.data!;
              final bubbles = <({bool staff, String body, DateTime at})>[
                (staff: false, body: ticket.message, at: ticket.createdAt),
                ...ticket.replies.map(
                  (r) => (staff: r.isStaff, body: r.body, at: r.createdAt),
                ),
              ];

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      itemCount: bubbles.length,
                      itemBuilder: (context, i) {
                        final b = bubbles[i];
                        final align = b.staff
                            ? Alignment.centerLeft
                            : Alignment.centerRight;
                        final bg = b.staff
                            ? theme.colorScheme.surfaceContainerHighest
                            : AppColors.orangeSoft;
                        return Align(
                          alignment: align,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: AppRadii.mdAll,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.body, style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text(
                                  '${b.staff ? 'Поддержка' : 'Вы'} · ${_fmt(b.at)}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: bottom > 0 ? 0 : 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Сообщение…',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        SizedBox(
                          width: 108,
                          child: AppButton(
                            label: 'Отправить',
                            loading: _sending,
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
