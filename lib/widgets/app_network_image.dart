import 'package:flutter/material.dart';

/// Network image with branded empty/error fallback (demo assets when URL fails).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.assetFallback,
    this.width,
    this.height,
  });

  final String? url;
  final BoxFit fit;
  final String? assetFallback;
  final double? width;
  final double? height;

  static const String defaultPromoAsset = 'assets/promotions/promotion1.png';
  static const String defaultCategoryAsset = 'assets/main/rolls.png';

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      return _fallback(context);
    }

    // Simulator/device: prefer loopback host over "localhost" hostname.
    final rewritten = u
        .replaceFirst('http://localhost:', 'http://127.0.0.1:')
        .replaceFirst('https://localhost:', 'https://127.0.0.1:');

    return Image.network(
      rewritten,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(context),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _fallback(BuildContext context) {
    final asset = assetFallback;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(asset, width: width, height: height, fit: fit);
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.restaurant_menu_outlined,
          size: 40,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
