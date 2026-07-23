import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no supabase runtime dependency in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('supabase_flutter'), isFalse);
    expect(pubspec.contains('dio:'), isTrue);
    expect(pubspec.contains('flutter_secure_storage:'), isTrue);
    expect(pubspec.contains('uuid:'), isTrue);
  });

  test('lib has no supabase or signInAnonymously references', () {
    final lib = Directory('lib');
    for (final file in lib.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      expect(
        source.toLowerCase().contains('supabase'),
        isFalse,
        reason: '${file.path} must not reference supabase',
      );
      expect(
        source.contains('signInAnonymously'),
        isFalse,
        reason: '${file.path} must not call signInAnonymously',
      );
    }
  });

  test('main.dart uses AppConfig and has no hardcoded API secrets', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source.contains('AppConfig.fromEnvironment'), isTrue);
    expect(source.contains('AppServices.init'), isTrue);
    expect(source.contains('eyJhbGciOi'), isFalse);
    expect(RegExp(r"url:\s*'https?://").hasMatch(source), isFalse);
  });

  test('admin editors do not call signInAnonymously', () {
    final files = [
      'lib/admin/categories/category_editor_page.dart',
      'lib/admin/products/product_editor_page.dart',
      'lib/admin/promotions/promotion_editor_page.dart',
    ];
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source.contains('signInAnonymously'), isFalse);
    }
  });
}
