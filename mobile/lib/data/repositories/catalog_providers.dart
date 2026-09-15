import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_providers.dart';
import '../../features/products/domain/product.dart';
import 'api_catalog_repository.dart';

final catalogSnapshotProvider = FutureProvider<CatalogSnapshot>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final results = await Future.wait([
    repo.getCategories(),
    repo.getProducts(),
  ]);
  return CatalogSnapshot(
    categories: results[0] as List<Category>,
    products: results[1] as List<Product>,
  );
});

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  return ref.watch(catalogRepositoryProvider).getProductsByCategory(categoryId);
});

final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  return ref.watch(catalogRepositoryProvider).getProductById(productId);
});

final pagedProductsProvider =
    FutureProvider.family<List<Product>, ProductQuery>((ref, query) async {
  final repo = ref.watch(catalogRepositoryProvider);
  if (repo is ApiCatalogRepository) {
    return (await repo.getProductsPage(
      page: query.page,
      limit: query.limit,
      categoryId: query.categoryId,
      search: query.search,
      brand: query.brand,
    ))
        .items;
  }
  if (query.categoryId != null) {
    return repo.getProductsByCategory(query.categoryId!);
  }
  final products = await repo.getProducts();
  if (query.brand != null) {
    return products
        .where((product) =>
            product.brand.toLowerCase() == query.brand!.toLowerCase())
        .toList();
  }
  return products;
});

final homeSectionsProvider = FutureProvider<List<HomeSection>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  if (repo is ApiCatalogRepository) {
    return repo.getHomeSections();
  }
  return const [];
});

final deliveryContextProvider =
    FutureProvider.family<DeliveryContext, DeliveryLocationQuery>(
  (ref, query) async {
    final repo = ref.watch(catalogRepositoryProvider);
    if (repo is ApiCatalogRepository) {
      return repo.getDeliveryContext(query);
    }
    return DeliveryContext(
      area: query.area.isNotEmpty ? query.area : 'your area',
      etaMinutes: 0,
      etaLabel: '',
      matched: false,
      serviceable: false,
      fallbackText:
          'Not currently serviceable in ${query.area.isNotEmpty ? query.area : 'your area'}',
    );
  },
);

class ProductQuery {
  const ProductQuery({
    this.page = 1,
    this.limit = 20,
    this.categoryId,
    this.search,
    this.brand,
  });

  final int page;
  final int limit;
  final String? categoryId;
  final String? search;
  final String? brand;

  @override
  bool operator ==(Object other) {
    return other is ProductQuery &&
        other.page == page &&
        other.limit == limit &&
        other.categoryId == categoryId &&
        other.search == search &&
        other.brand == brand;
  }

  @override
  int get hashCode => Object.hash(page, limit, categoryId, search, brand);
}
