import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_catalog_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/datasources/mock_catalog_datasource.dart';
import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';
import 'api_client.dart';
import 'api_services.dart';

final tokenStorageProvider = Provider<SecureTokenStorage>(
  (_) => SecureTokenStorage(),
);

final sessionExpiredProvider = StateProvider<int>((_) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    onSessionExpired: () async {
      ref.read(sessionExpiredProvider.notifier).state++;
    },
  );
});

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

final cartApiProvider = Provider<CartApi>(
  (ref) => CartApi(ref.watch(apiClientProvider)),
);

final addressApiProvider = Provider<AddressApi>(
  (ref) => AddressApi(ref.watch(apiClientProvider)),
);

final orderApiProvider = Provider<OrderApi>(
  (ref) => OrderApi(ref.watch(apiClientProvider)),
);

final paymentApiProvider = Provider<PaymentApi>(
  (ref) => PaymentApi(ref.watch(apiClientProvider)),
);

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(apiClientProvider)),
);

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.useMockData) return MockCatalogRepository();
  return ApiCatalogRepository(ref.watch(apiClientProvider));
});
