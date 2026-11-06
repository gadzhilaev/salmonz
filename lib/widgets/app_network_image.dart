import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum AppImageKind {
  /// Dish / product photo — contain, padded, no crop of the food.
  dish,

  /// Full-bleed banner / promo — cover.
  banner,

  /// Avatar / circular crop.
  avatar,

  /// Category illustration — contain.
  category,
}

/// Cached network image with kind-aware fit and stable placeholders.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.kind = AppImageKind.dish,
    this.fit,
    this.assetFallback,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
  });

  final String? url;
  final AppImageKind kind;
  final BoxFit? fit;
  final String? assetFallback;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  static const String defaultPromoAsset = 'assets/promotions/promotion1.png';
  static const String defaultCategoryAsset = 'assets/main/rolls.png';

  static final Set<String> _precacheInFlight = {};

  BoxFit get _resolvedFit =>
      fit ??
      switch (kind) {
        // Dish: contain keeps the plate intact; category overlays the tile tint.
        AppImageKind.dish || AppImageKind.category => BoxFit.contain,
        AppImageKind.banner || AppImageKind.avatar => BoxFit.cover,
      };

  EdgeInsetsGeometry get _resolvedPadding =>
      padding ??
      switch (kind) {
        // No inset pad — avoids a second “photo square” inside the card.
        AppImageKind.dish ||
        AppImageKind.category ||
        AppImageKind.banner ||
        AppImageKind.avatar => EdgeInsets.zero,
      };

  /// Bump when seed/demo media files change under the same object key so
  /// CachedNetworkImage does not keep a stale disk entry on localhost.
  static const String mediaCacheEpoch = '20261107b';

  static String? rewriteUrl(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty) return null;
    var out = u
        .replaceFirst('http://localhost:', 'http://127.0.0.1:')
        .replaceFirst('https://localhost:', 'https://127.0.0.1:');
    final host = out.contains('127.0.0.1') || out.contains('localhost');
    if (host && !out.contains('v=$mediaCacheEpoch')) {
      out = '$out${out.contains('?') ? '&' : '?'}v=$mediaCacheEpoch';
    }
    return out;
  }

  /// Best-effort warm of disk/memory cache. Dedupes in-flight URLs.
  static Future<void> precacheUrls(
    BuildContext context,
    Iterable<String?> urls, {
    int limit = 12,
  }) async {
    var n = 0;
    final futures = <Future<void>>[];
    for (final raw in urls) {
      if (n >= limit) break;
      final u = rewriteUrl(raw);
      if (u == null) continue;
      if (!_precacheInFlight.add(u)) continue;
      n++;
      futures.add(() async {
        try {
          await precacheImage(CachedNetworkImageProvider(u), context);
        } catch (_) {
        } finally {
          _precacheInFlight.remove(u);
        }
      }());
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final rewritten = rewriteUrl(url);
    final themeBg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceAlt;
    // Category tiles sit on a colored Material — keep the image layer transparent
    // so we don't paint a white/gray photo plate inside the card.
    final Color bg = backgroundColor ??
        switch (kind) {
          AppImageKind.category => Colors.transparent,
          AppImageKind.dish => Colors.transparent,
          AppImageKind.banner || AppImageKind.avatar => themeBg,
        };

    Widget content;
    if (rewritten == null) {
      content = _fallback(context, bg);
    } else {
      content = CachedNetworkImage(
        imageUrl: rewritten,
        width: width,
        height: height,
        fit: _resolvedFit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 180),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => _skeleton(context, bg),
        errorWidget: (_, __, ___) => _fallback(context, bg),
      );
    }

    final padded = Padding(padding: _resolvedPadding, child: content);
    final Widget boxed = bg == Colors.transparent
        ? padded
        : ColoredBox(color: bg, child: padded);

    Widget child = sized(boxed);
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget sized(Widget child) {
    if (width == null && height == null) {
      return SizedBox.expand(child: child);
    }
    return SizedBox(width: width, height: height, child: child);
  }

  Widget _skeleton(BuildContext context, Color bg) {
    final box = Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
    if (bg == Colors.transparent) return box;
    return ColoredBox(color: bg, child: box);
  }

  Widget _fallback(BuildContext context, Color bg) {
    final asset = assetFallback;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: _resolvedFit,
      );
    }
    return ColoredBox(
      color: bg,
      child: Center(
        child: Icon(
          Icons.restaurant_menu_outlined,
          size: 32,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
