/// Typed runtime configuration for Salmonz.
///
/// Values are injected at compile/run time via `--dart-define` or
/// `--dart-define-from-file`. No secrets belong in source control.
///
/// Plain `flutter run` uses [defaultLocalApiBaseUrl] (iOS simulator / desktop).
/// Override for Android emulator (`http://10.0.2.2:3000`) or a device LAN IP.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.appEnv = 'local',
    this.isDemo = true,
  });

  /// NestJS API origin (no trailing slash), e.g. `http://10.0.2.2:3000`.
  final String apiBaseUrl;

  /// Logical environment label: `local`, `demo`, `prod`, etc.
  final String appEnv;

  /// When true, UI/docs may treat the backend as a disposable demo.
  final bool isDemo;

  /// Loopback API used when no `--dart-define=API_BASE_URL` is passed.
  /// Not a production host — safe demo default for simulator/desktop.
  static const defaultLocalApiBaseUrl = 'http://127.0.0.1:3000';

  /// Full REST prefix including version.
  String get apiV1Base => '${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/api/v1';

  static const _urlDefine = 'API_BASE_URL';
  static const _envDefine = 'APP_ENV';
  static const _demoDefine = 'APP_DEMO';

  /// Reads configuration from compile-time environment defines.
  ///
  /// Missing defines fall back to local demo defaults (not production).
  /// Explicit empty `API_BASE_URL=` still fails validation in [fromValues].
  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment(
      _urlDefine,
      defaultValue: defaultLocalApiBaseUrl,
    );
    const appEnv = String.fromEnvironment(_envDefine, defaultValue: 'local');
    const isDemo = bool.fromEnvironment(_demoDefine, defaultValue: true);

    return AppConfig.fromValues(
      apiBaseUrl: url,
      appEnv: appEnv,
      isDemo: isDemo,
    );
  }

  /// Validates and builds config from explicit values (tests / tooling).
  factory AppConfig.fromValues({
    required String apiBaseUrl,
    String appEnv = 'local',
    bool isDemo = true,
  }) {
    final url = apiBaseUrl.trim();

    if (url.isEmpty) {
      throw const AppConfigException(
        'Missing API_BASE_URL. Pass --dart-define=API_BASE_URL=... '
        'or --dart-define-from-file=config/local.json '
        '(plain flutter run defaults to http://127.0.0.1:3000)',
      );
    }

    return AppConfig(
      apiBaseUrl: url.replaceAll(RegExp(r'/+$'), ''),
      appEnv: appEnv.trim().isEmpty ? 'local' : appEnv.trim(),
      isDemo: isDemo,
    );
  }
}

/// Configuration error safe for logs and UI (does not include key material).
class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
