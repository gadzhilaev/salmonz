import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Centers content with semantic padding and optional max width.
class AppPageContainer extends StatelessWidget {
  const AppPageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  /// Narrower column for auth / dense forms.
  factory AppPageContainer.form({Key? key, required Widget child}) {
    return AppPageContainer(
      key: key,
      maxWidth: AppBreakpoints.formMaxWidth,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pad =
            padding ??
            EdgeInsets.symmetric(
              horizontal: AppBreakpoints.pagePadding(parentW),
            );

        return Padding(
          padding: pad,
          child: Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Full-width body that still respects content max on tablets.
class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.children,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.padding,
    this.physics,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pad =
            padding ??
            EdgeInsets.symmetric(horizontal: AppBreakpoints.pagePadding(width));
        return ListView(
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          padding: pad,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
