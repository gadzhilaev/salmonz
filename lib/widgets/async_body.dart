import 'package:flutter/material.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/widgets/app_error_view.dart';

/// Builds loading, error, optional empty, or data from [AsyncSnapshot].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.snapshot,
    required this.builder,
    this.onRetry,
    this.loading,
    this.empty,
    this.scrollable = false,
    this.waitForData = false,
  });

  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final Future<void> Function()? onRetry;
  final Widget? loading;
  final Widget? empty;
  final bool scrollable;

  /// When true, keeps showing [loading] until [ConnectionState.done] even if
  /// stale data is present (matches RefreshIndicator reload patterns).
  final bool waitForData;

  @override
  Widget build(BuildContext context) {
    final waiting = waitForData
        ? snapshot.connectionState != ConnectionState.done
        : !snapshot.hasData && snapshot.connectionState != ConnectionState.done;

    if (waiting) {
      return loading ?? const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final errorView = AppErrorView(
        message: ApiException.userMessageFrom(snapshot.error!),
        onRetry: onRetry == null ? null : () => onRetry!(),
      );
      if (scrollable) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [const SizedBox(height: 160), errorView],
        );
      }
      return Center(child: errorView);
    }

    final data = snapshot.data;
    if (data == null) {
      return empty ?? const SizedBox.shrink();
    }

    return builder(data);
  }
}
