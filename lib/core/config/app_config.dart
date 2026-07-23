/// Typed runtime configuration for Salmonz.
///
/// Values are injected at compile/run time via `--dart-define` or
/// `--dart-define-from-file`. No secrets belong in source control.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.appEnv = 'local',
    this.isDemo = true,
  });

  /// Supabase project URL (local or demo cloud).
  final String supabaseUrl;

  /// Publishable (anon) key only — never the service-role / secret key.
  final String supabasePublishableKey;

  /// Logical environment label: `local`, `demo`, `prod`, etc.
  final String appEnv;

  /// When true, UI/docs may treat the backend as a disposable demo.
  final bool isDemo;

  static const _urlDefine = 'SUPABASE_URL';
  static const _keyDefine = 'SUPABASE_PUBLISHABLE_KEY';
  static const _envDefine = 'APP_ENV';
  static const _demoDefine = 'APP_DEMO';

  /// Reads configuration from compile-time environment defines.
  ///
  /// Throws [AppConfigException] when required values are missing.
  /// Never embeds or falls back to a production URL/key.
  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment(_urlDefine);
    const key = String.fromEnvironment(_keyDefine);
    const appEnv = String.fromEnvironment(_envDefine, defaultValue: 'local');
    const isDemo = bool.fromEnvironment(_demoDefine, defaultValue: true);

    return AppConfig.fromValues(
      supabaseUrl: url,
      supabasePublishableKey: key,
      appEnv: appEnv,
      isDemo: isDemo,
    );
  }

  /// Validates and builds config from explicit values (tests / tooling).
  factory AppConfig.fromValues({
    required String supabaseUrl,
    required String supabasePublishableKey,
    String appEnv = 'local',
    bool isDemo = true,
  }) {
    final url = supabaseUrl.trim();
    final key = supabasePublishableKey.trim();

    if (url.isEmpty) {
      throw const AppConfigException(
        'Missing SUPABASE_URL. Pass --dart-define=SUPABASE_URL=... '
        'or --dart-define-from-file=config/local.json',
      );
    }
    if (key.isEmpty) {
      throw const AppConfigException(
        'Missing SUPABASE_PUBLISHABLE_KEY. Pass '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=... '
        'or --dart-define-from-file=config/local.json',
      );
    }

    return AppConfig(
      supabaseUrl: url,
      supabasePublishableKey: key,
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
