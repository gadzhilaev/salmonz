import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/token_store.dart';
import '../../data/repositories/addresses_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/support_repository.dart';

/// App-wide service locator initialized once in [main].
class AppServices {
  AppServices._(this.config, this.tokenStore, this.api);

  final AppConfig config;
  final TokenStore tokenStore;
  final ApiClient api;

  late final AuthRepository auth = AuthRepository(api, tokenStore);
  late final CatalogRepository catalog = CatalogRepository(api);
  late final AddressesRepository addresses = AddressesRepository(api);
  late final OrdersRepository orders = OrdersRepository(api);
  late final SupportRepository support = SupportRepository(api);
  late final ProfileRepository profile = ProfileRepository(api);
  late final AdminRepository admin = AdminRepository(api);

  static AppServices? _instance;

  static AppServices get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'AppServices not initialized. Call AppServices.init first.',
      );
    }
    return i;
  }

  static bool get isInitialized => _instance != null;

  static AppServices init({
    required AppConfig config,
    TokenStore? tokenStore,
    ApiClient? apiClient,
    void Function()? onSessionExpired,
  }) {
    final tokens = tokenStore ?? TokenStore();
    final api =
        apiClient ??
        ApiClient(
          config: config,
          tokenStore: tokens,
          onSessionExpired: onSessionExpired,
        );
    return _instance = AppServices._(config, tokens, api);
  }

  /// Test helper.
  static void reset() => _instance = null;
}
