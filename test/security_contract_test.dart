import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin editors no longer call signInAnonymously', () {
    final files = [
      'lib/admin/categories/category_editor_page.dart',
      'lib/admin/products/product_editor_page.dart',
      'lib/admin/promotions/promotion_editor_page.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('signInAnonymously'),
        isFalse,
        reason: '$path must not call signInAnonymously',
      );
    }
  });

  test('registration does not insert profile when trigger owns creation', () {
    final source = File('lib/auth/register.dart').readAsStringSync();
    expect(
      source.contains("from('user').insert"),
      isFalse,
      reason: 'Client must not insert into user; DB trigger creates the row',
    );
  });

  test('main.dart has no hardcoded Supabase URL or key literals', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source.contains('supabase.co'), isFalse);
    expect(source.contains('eyJhbGciOi'), isFalse);
    expect(RegExp(r"url:\s*'https?://").hasMatch(source), isFalse);
    expect(source.contains('AppConfig.fromEnvironment'), isTrue);
  });
}
