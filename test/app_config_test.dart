import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('accepts valid API_BASE_URL', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: 'http://10.0.2.2:3000',
        appEnv: 'local',
        isDemo: true,
      );

      expect(config.apiBaseUrl, 'http://10.0.2.2:3000');
      expect(config.apiV1Base, 'http://10.0.2.2:3000/api/v1');
      expect(config.appEnv, 'local');
      expect(config.isDemo, isTrue);
    });

    test('throws clear error when API_BASE_URL is empty', () {
      expect(
        () => AppConfig.fromValues(apiBaseUrl: '   '),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });

    test('strips trailing slash from base URL', () {
      final config = AppConfig.fromValues(apiBaseUrl: 'http://127.0.0.1:3000/');
      expect(config.apiBaseUrl, 'http://127.0.0.1:3000');
      expect(config.apiV1Base, 'http://127.0.0.1:3000/api/v1');
    });

    test('does not fall back to a hardcoded production host', () {
      expect(
        () => AppConfig.fromValues(apiBaseUrl: ''),
        throwsA(isA<AppConfigException>()),
      );

      try {
        AppConfig.fromValues(apiBaseUrl: '');
      } on AppConfigException catch (e) {
        expect(e.message.toLowerCase(), isNot(contains('supabase.co')));
        expect(e.message, isNot(contains('vwerkkbccwosrnkozgza')));
      }
    });
  });
}
