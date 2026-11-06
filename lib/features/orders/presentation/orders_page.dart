import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/pages/order_details_page.dart';
import 'package:salmonz/widgets/app_empty_state.dart';
import 'package:salmonz/widgets/app_error_view.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_nav_bar.dart';
import 'package:salmonz/widgets/app_root.dart';
import 'package:salmonz/widgets/price_text.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<OrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.orders.list();
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final d = dt.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]}, $hh:$mm';
  }

  static String _statusRu(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'Новый';
      case 'CONFIRMED':
        return 'Подтверждён';
      case 'PREPARING':
        return 'Готовится';
      case 'READY':
        return 'Готов';
      case 'DELIVERING':
        return 'Доставляется';
      case 'COMPLETED':
        return 'Завершён';
      case 'CANCELLED':
        return 'Отменён';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CANCELLED':
        return AppColors.error;
      case 'COMPLETED':
        return AppColors.success;
      case 'PREPARING':
      case 'READY':
      case 'DELIVERING':
        return AppColors.orange;
      default:
        return AppColors.info;
    }
  }

  static String _itemsSummary(OrderModel o) {
    if (o.items.isEmpty) return 'Состав недоступен';
    final names = o.items.map((e) => e.productName).where((n) => n.isNotEmpty);
    final list = names.take(2).toList();
    final rest = o.items.length - list.length;
    final head = list.join(', ');
    if (rest > 0) return '$head и ещё $rest';
    return head;
  }

  static String _shortNumber(OrderModel o) {
    final raw = o.publicNumber.trim();
    if (raw.isEmpty) {
      return o.id.length >= 4 ? o.id.substring(0, 4).toUpperCase() : '—';
    }
    // Prefer last meaningful chunk for human-readable display.
    final parts = raw.split(RegExp(r'[\s\-_/]+'));
    final last = parts.isNotEmpty ? parts.last : raw;
    if (last.length <= 8) return last.toUpperCase();
    return last.substring(last.length - 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.tab(title: 'Заказы'),
      body: AppPageContainer(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = AppServices.instance.orders.list();
            });
            try {
              await _future;
            } catch (_) {}
          },
          child: FutureBuilder<List<OrderModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    AppErrorView(
                      message: ApiException.userMessageFrom(snap.error!),
                      onRetry: () {
                        setState(() {
                          _future = AppServices.instance.orders.list();
                        });
                      },
                    ),
                  ],
                );
              }
              final orders = snap.data ?? [];
              if (orders.isEmpty) {
                return AppEmptyState(
                  title: 'Заказов пока нет',
                  message: 'Оформите первый заказ из меню',
                  icon: Icons.receipt_long_outlined,
                  actionLabel: 'Посмотреть меню',
                  onAction: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const AppRoot(initialTab: AppTab.home),
                      ),
                      (_) => false,
                    );
                  },
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  bottom: AppSpacing.lg,
                ),
                itemCount: orders.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final o = orders[index];
                  final statusColor = _statusColor(o.status);
                  return Material(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadii.mdAll,
                    child: InkWell(
                      borderRadius: AppRadii.mdAll,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsPage(orderId: o.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Заказ № ${_shortNumber(o)}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: AppRadii.smAll,
                                  ),
                                  child: Text(
                                    _statusRu(o.status),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmtDate(o.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _itemsSummary(o),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Text(
                                  '${o.items.fold<int>(0, (s, e) => s + e.quantity)} поз.',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const Spacer(),
                                PriceText(o.total),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
