import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/widgets/add_to_cart_button.dart';
import 'package:salmonz/widgets/app_empty_state.dart';
import 'package:salmonz/widgets/app_error_view.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:salmonz/widgets/price_text.dart';

import 'product_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.title,
    required this.categoryId,
  });
  final String title;
  final String categoryId;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProducts();
  }

  Future<List<ProductModel>> _loadProducts() async {
    final page = await AppServices.instance.catalog.getProducts(
      categoryId: widget.categoryId,
      limit: 100,
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppNetworkImage.precacheUrls(
          context,
          page.data.take(10).map((e) => e.imageUrl),
          limit: 10,
        );
      });
    }
    return page.data;
  }

  int _columnsFor(BuildContext context, double width) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (width < 360 || textScale >= 1.35) return 1;
    if (width >= AppBreakpoints.mediumMax) return 4;
    if (width >= AppBreakpoints.compactMax) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = _columnsFor(context, width);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader.nested(title: widget.title),
      body: AppPageContainer(
        child: FutureBuilder<List<ProductModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: AppErrorView(
                  message: ApiException.userMessageFrom(snap.error!),
                  onRetry: () {
                    setState(() => _future = _loadProducts());
                  },
                ),
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const AppEmptyState(
                title: 'Пока пусто',
                message: 'В этой категории пока нет блюд',
                icon: Icons.ramen_dining_outlined,
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                // Compact: image + text + full-width CTA, less empty air.
                childAspectRatio: columns == 1 ? 2.4 : 0.70,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _ProductCard(
                  product: items[index],
                  horizontal: columns == 1,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.horizontal = false});

  final ProductModel product;
  final bool horizontal;

  CartItem get _line => CartItem(
    id: product.id,
    name: product.name,
    img: product.imageUrl ?? '',
    price: product.price,
    gramm: product.weight ?? 0,
    amount: 1,
  );

  void _add() => Cart.instance.add(_line);

  void _setQty(int v) => Cart.instance.upsert(_line, v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inStock = product.isAvailable;
    final desc = product.description.trim();
    final weight = product.weight;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadii.mdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: inStock
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductPage(product: product),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          child: horizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 100, height: 100, child: _image()),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _body(theme, desc, weight, inStock)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _image()),
                    const SizedBox(height: AppSpacing.xs),
                    _body(theme, desc, weight, inStock),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _image() {
    return Opacity(
      opacity: product.isAvailable ? 1 : 0.45,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: AppNetworkImage(
          url: product.imageUrl,
          kind: AppImageKind.dish,
          borderRadius: AppRadii.smAll,
          memCacheWidth: 480,
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, String desc, int? weight, bool inStock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
          ),
        ],
        if (weight != null && weight > 0) ...[
          const SizedBox(height: 2),
          Text('$weight г', style: theme.textTheme.labelMedium),
        ],
        const SizedBox(height: AppSpacing.xs),
        PriceText(product.price),
        const SizedBox(height: AppSpacing.xs),
        AnimatedBuilder(
          animation: Cart.instance,
          builder: (context, _) {
            final qty = Cart.instance.quantityOf(product.id);
            if (!inStock) {
              return Text(
                'Нет в наличии',
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              );
            }
            return AddToCartButton(
              key: Key('add_${product.id}'),
              quantity: qty,
              onAdd: _add,
              onChanged: _setQty,
              height: 38,
            );
          },
        ),
      ],
    );
  }
}
