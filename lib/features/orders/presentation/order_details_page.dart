import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/profile/support_page.dart';
import 'package:salmonz/widgets/app_button.dart';
import 'package:salmonz/widgets/app_card.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/async_body.dart';
import 'package:salmonz/widgets/price_text.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<OrderModel> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.orders.get(widget.orderId);
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';

  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
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
        return 'В обработке';
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

  static String _shortNumber(OrderModel o) {
    final raw = o.publicNumber.trim();
    if (raw.isEmpty) {
      return o.id.length >= 4 ? o.id.substring(0, 4).toUpperCase() : '—';
    }
    final parts = raw.split(RegExp(r'[\s\-_/]+'));
    final last = parts.isNotEmpty ? parts.last : raw;
    if (last.length <= 8) return last.toUpperCase();
    return last.substring(last.length - 6).toUpperCase();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.orders.get(widget.orderId);
    });
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.nested(title: 'Заказ'),
      body: SafeArea(
        child: AppPageContainer(
          child: FutureBuilder<OrderModel>(
            future: _future,
            builder: (context, snap) {
              return AsyncBody<OrderModel>(
                snapshot: snap,
                onRetry: _reload,
                scrollable: true,
                builder: (o) {
                  final statusColor = _statusColor(o.status);
                  return ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '№ ${_shortNumber(o)}',
                                    style: theme.textTheme.titleLarge,
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
                            const SizedBox(height: 6),
                            Text(
                              _fmtDate(o.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Доставка', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            if (o.addressText.isNotEmpty)
                              Text(
                                o.addressText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 4),
                            Text(o.phone, style: theme.textTheme.bodyMedium),
                            if ((o.comment ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Комментарий: ${o.comment}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Состав', style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppSpacing.sm),
                            for (final item in o.items) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: AppNetworkImage(
                                      url: null,
                                      kind: AppImageKind.dish,
                                      borderRadius: AppRadii.smAll,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.unitPrice.formatRub()} × ${item.quantity}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PriceText(item.lineTotal),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            const Divider(),
                            _SumRow(
                              label: 'Товары',
                              value: o.subtotal.formatRub(),
                            ),
                            _SumRow(
                              label: 'Доставка',
                              value: o.deliveryFee.minorUnits == 0
                                  ? 'Бесплатно'
                                  : o.deliveryFee.formatRub(),
                            ),
                            const SizedBox(height: 6),
                            _SumRow(
                              label: 'Итого',
                              value: o.total.formatRub(),
                              emphasize: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Написать в поддержку',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.support_agent_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupportPage(),
                            ),
                          );
                        },
                      ),
                    ],
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

class _SumRow extends StatelessWidget {
  const _SumRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
