import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('accepts valid values', () {
      final config = AppConfig.fromValues(
        supabaseUrl: 'http://127.0.0.1:54321',
        supabasePublishableKey: 'test-publishable-key',
        appEnv: 'local',
        isDemo: true,
      );

      expect(config.supabaseUrl, 'http://127.0.0.1:54321');
      expect(config.supabasePublishableKey, 'test-publishable-key');
      expect(config.appEnv, 'local');
      expect(config.isDemo, isTrue);
    });

    test('throws clear error when URL is empty', () {
      expect(
        () => AppConfig.fromValues(
          supabaseUrl: '   ',
          supabasePublishableKey: 'test-publishable-key',
        ),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });

    test('throws clear error when publishable key is empty', () {
      expect(
        () => AppConfig.fromValues(
          supabaseUrl: 'http://127.0.0.1:54321',
          supabasePublishableKey: '',
        ),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_PUBLISHABLE_KEY'),
          ),
        ),
      );
    });

    test('error message does not include key material', () {
      const secretish = 'super-secret-publishable-value-xyz';
      try {
        AppConfig.fromValues(
          supabaseUrl: '',
          supabasePublishableKey: secretish,
        );
        fail('expected AppConfigException');
      } on AppConfigException catch (e) {
        expect(e.toString().contains(secretish), isFalse);
        expect(e.message.contains(secretish), isFalse);
      }
    });

    test('does not fall back to a hardcoded production host', () {
      expect(
        () =>
            AppConfig.fromValues(supabaseUrl: '', supabasePublishableKey: 'k'),
        throwsA(isA<AppConfigException>()),
      );

      // Ensure factory path has no silent default URL baked in.
      try {
        AppConfig.fromValues(supabaseUrl: '', supabasePublishableKey: 'k');
      } on AppConfigException catch (e) {
        expect(e.message.toLowerCase(), isNot(contains('supabase.co')));
        expect(e.message, isNot(contains('vwerkkbccwosrnkozgza')));
      }
    });
  });
}
