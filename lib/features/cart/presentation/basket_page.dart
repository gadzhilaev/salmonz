import 'package:flutter/material.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/pages/checkout_page.dart';
import 'package:salmonz/widgets/app_button.dart';
import 'package:salmonz/widgets/app_card.dart';
import 'package:salmonz/widgets/app_empty_state.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_nav_bar.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/app_root.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:salmonz/widgets/price_text.dart';
import 'package:salmonz/widgets/quantity_selector.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.tab(title: 'Корзина'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: AppPageContainer(
          child: AnimatedBuilder(
            animation: cart,
            builder: (_, __) {
              final items = cart.items;
              if (items.isEmpty) {
                return AppEmptyState(
                  title: 'Корзина пуста',
                  message: 'Добавьте блюда из меню, чтобы оформить заказ',
                  icon: Icons.shopping_bag_outlined,
                  actionLabel: 'Перейти в меню',
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

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.xs,
                        0,
                        AppSpacing.sm,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _BasketTile(item: items[i]),
                    ),
                  ),
                  _CheckoutBar(
                    totalLabel: cart.totalSum.formatRub(),
                    onCheckout: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutPage()),
                      );
                    },
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

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.totalLabel, required this.onCheckout});

  final String totalLabel;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Итого', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(totalLabel, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const Key('cartCheckoutButton'),
              label: 'Оформить заказ',
              onPressed: onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketTile extends StatelessWidget {
  const _BasketTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = Cart.instance;
    final meta = [
      if (item.gramm > 0) '${item.gramm} г',
      '${item.price.formatRub()} / шт.',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: AppNetworkImage(
                  url: item.img.isEmpty ? null : item.img,
                  kind: AppImageKind.dish,
                  borderRadius: AppRadii.smAll,
                  memCacheWidth: 200,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Удалить',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => cart.remove(item.id),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              QuantitySelector(
                quantity: item.qty,
                dense: true,
                filled: true,
                min: 0,
                onChanged: (v) => cart.setQuantity(item.id, v),
              ),
              const Spacer(),
              PriceText(item.subtotal),
            ],
          ),
        ],
      ),
    );
  }
}
