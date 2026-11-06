import 'package:flutter/material.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/widgets/add_to_cart_button.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:salmonz/widgets/price_text.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.product});

  final ProductModel product;

  CartItem get _line => CartItem(
    id: product.id,
    name: product.name,
    img: product.imageUrl ?? '',
    price: product.price,
    gramm: product.weight ?? 0,
    amount: 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = product.imageUrl ?? '';
    final weight = product.weight ?? 0;
    final desc = product.description.trim();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppHeader.nested(title: product.name),
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    AspectRatio(
                      aspectRatio: 1.2,
                      child: AppNetworkImage(
                        url: img.isEmpty ? null : img,
                        kind: AppImageKind.dish,
                        borderRadius: AppRadii.mdAll,
                        memCacheWidth: 900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(product.name, style: theme.textTheme.headlineSmall),
                    if (weight > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text('$weight г', style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    PriceText(product.price),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('Состав', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(desc, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AnimatedBuilder(
                  animation: Cart.instance,
                  builder: (context, _) {
                    final qty = Cart.instance.quantityOf(product.id);
                    return AddToCartButton(
                      key: const Key('addToCart'),
                      quantity: qty,
                      onAdd: () => Cart.instance.add(_line),
                      onChanged: (v) => Cart.instance.upsert(_line, v),
                      enabled: product.isAvailable,
                      height: 48,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
