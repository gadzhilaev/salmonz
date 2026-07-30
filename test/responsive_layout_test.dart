import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/responsive/responsive_grid.dart';
import 'package:salmonz/core/theme/app_theme.dart';
import 'package:salmonz/widgets/app_nav_bar.dart';
import 'package:salmonz/widgets/app_shell.dart';

void main() {
  group('AppBreakpoints', () {
    test('classifies compact/medium/expanded', () {
      expect(AppBreakpoints.ofWidth(390), AppBreakpoint.compact);
      expect(AppBreakpoints.ofWidth(800), AppBreakpoint.medium);
      expect(AppBreakpoints.ofWidth(1100), AppBreakpoint.expanded);
    });

    test('rail needs wide + tablet shortestSide', () {
      expect(AppBreakpoints.useNavigationRail(839), isFalse);
      expect(
        AppBreakpoints.useNavigationRailForSize(const Size(844, 390)),
        isFalse,
      );
      expect(
        AppBreakpoints.useNavigationRailForSize(const Size(1024, 1366)),
        isTrue,
      );
    });

    test('grid columns clamp', () {
      expect(AppBreakpoints.gridColumns(400, minCardWidth: 220), 1);
      expect(AppBreakpoints.gridColumns(700, minCardWidth: 220), 3);
      expect(
        AppBreakpoints.gridColumns(1200, minCardWidth: 220, maxColumns: 4),
        4,
      );
    });
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        darkTheme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: AppShell(
            pages: List.generate(
              4,
              (i) => Scaffold(
                body: Center(child: Text('tab-$i', key: Key('tab-$i'))),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compact uses bottom NavigationBar chrome', (tester) async {
    await pumpShell(tester, size: const Size(390, 844));
    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('tab-0')), findsOneWidget);
  });

  testWidgets('expanded uses NavigationRail', (tester) async {
    await pumpShell(tester, size: const Size(1024, 1366));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);
  });

  testWidgets('iPhone landscape keeps bottom bar', (tester) async {
    await pumpShell(tester, size: const Size(844, 390));
    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('iPad landscape rail + no overflow', (tester) async {
    await pumpShell(tester, size: const Size(1366, 1024));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 1.3 no overflow on shell', (tester) async {
    await pumpShell(tester, size: const Size(1024, 1366), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme shell', (tester) async {
    await pumpShell(tester, size: const Size(820, 1180), theme: AppTheme.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppPageContainer.form constrains width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPageContainer.form(
            child: const SizedBox(
              key: Key('formInner'),
              height: 40,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final box = tester.renderObject<RenderBox>(
      find.byKey(const Key('formInner')),
    );
    expect(box.size.width, lessThanOrEqualTo(AppBreakpoints.formMaxWidth));
    expect(box.size.width, greaterThan(300));
  });

  testWidgets('ResponsiveGrid fills width with multiple columns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ResponsiveGrid(
              itemCount: 6,
              minCardWidth: 220,
              maxColumns: 4,
              itemHeight: 100,
              itemBuilder: (context, i, w) => ColoredBox(
                color: Colors.orange,
                child: Text('c$i', key: Key('cell-$i')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cell-0')), findsOneWidget);
    final first = tester.getRect(find.byKey(const Key('cell-0')));
    final second = tester.getRect(find.byKey(const Key('cell-1')));
    // Second cell is to the right on a wide grid (same row).
    expect(second.left, greaterThan(first.left));
    expect(first.width, greaterThan(200));
  });
}
