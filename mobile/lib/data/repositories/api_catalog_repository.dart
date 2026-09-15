import '../../core/network/api_client.dart';
import '../../core/network/api_services.dart';
import '../../features/products/domain/product.dart';
import 'catalog_repository.dart';

class CatalogPage {
  const CatalogPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Product> items;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;
}

class ApiCatalogRepository implements CatalogRepository {
  const ApiCatalogRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Category>> getCategories() async {
    final response = await _client.dio.get<dynamic>('/categories');
    final data = unwrapData<List<dynamic>>(response);
    return data.map((item) {
      final json = item as Map<String, dynamic>;
      return Category(
        id: (json['id'] ?? json['slug']).toString(),
        name: (json['name'] ?? json['name_en'] ?? '').toString(),
        image: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
        tintHex: (json['tint'] ?? '#FFE9D6').toString(),
      );
    }).toList();
  }

  @override
  Future<List<Product>> getProducts() async {
    const limit = 500;
    final products = <Product>[];
    var page = 1;
    var total = 0;

    do {
      final response = await getProductsPage(page: page, limit: limit);
      total = response.total;
      products.addAll(response.items);
      if (!response.hasMore || response.items.isEmpty) break;
      page += 1;
    } while (products.length < total);

    // Cart validation needs an app-wide active catalog snapshot. Using only the
    // first home-page slice can make valid cart items look removed/unavailable.
    return mergeDuplicateProducts(products);
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    return (await getProductsPage(categoryId: categoryId, limit: 500)).items;
  }

  @override
  Future<Product?> getProductById(String productId) async {
    final response = await _client.dio.get<dynamic>('/products/$productId');
    final data = unwrapData<Map<String, dynamic>?>(response);
    if (data == null) return null;
    return productFromApi(data);
  }

  Future<CatalogPage> getProductsPage({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    String? brand,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
      },
    );
    final data = unwrapData<Map<String, dynamic>>(response);
    final items = data['items'] as List<dynamic>? ?? const [];
    return CatalogPage(
      items: mergeDuplicateProducts(items
          .map((item) => productFromApi(item as Map<String, dynamic>))
          .toList()),
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
      total: (data['total'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<List<HomeSection>> getHomeSections({String? sectionKey}) async {
    final response = await _client.dio.get<dynamic>(
      '/home-sections',
      queryParameters: {
        if (sectionKey != null && sectionKey.isNotEmpty)
          'sectionKey': sectionKey,
      },
    );
    final data = unwrapData<List<dynamic>>(response);
    return data
        .map((item) => HomeSection.fromJson(item as Map<String, dynamic>))
        .where((section) => section.products.isNotEmpty)
        .toList();
  }

  Future<DeliveryContext> getDeliveryContext(
      DeliveryLocationQuery query) async {
    final response = await _client.dio.get<dynamic>(
      '/delivery-context',
      queryParameters: {
        if (query.area.isNotEmpty) 'area': query.area,
        if (query.city.isNotEmpty) 'city': query.city,
        if (query.pincode.isNotEmpty) 'pincode': query.pincode,
      },
    );
    return DeliveryContext.fromJson(unwrapData<Map<String, dynamic>>(response));
  }
}

final class CatalogSnapshot {
  const CatalogSnapshot({
    required this.categories,
    required this.products,
  });

  final List<Category> categories;
  final List<Product> products;
}

final class HomeSection {
  const HomeSection({
    required this.id,
    required this.sectionKey,
    required this.title,
    required this.products,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String sectionKey;
  final String title;
  final List<Product> products;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return HomeSection(
      id: json['id'].toString(),
      sectionKey: (json['sectionKey'] ?? json['section_key'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      startsAt: DateTime.tryParse(
        (json['startsAt'] ?? json['starts_at'] ?? '').toString(),
      ),
      endsAt: DateTime.tryParse(
        (json['endsAt'] ?? json['ends_at'] ?? '').toString(),
      ),
      products: mergeDuplicateProducts(items
          .map((item) {
            final json = item as Map<String, dynamic>;
            final product = json['product'];
            if (product is! Map<String, dynamic>) return null;
            return productFromApi(product);
          })
          .whereType<Product>()
          .toList()),
    );
  }

  bool isVisible(DateTime now) {
    final starts = startsAt;
    final ends = endsAt;
    if (starts != null && starts.isAfter(now)) return false;
    if (ends != null && !ends.isAfter(now)) return false;
    return products.isNotEmpty;
  }

  bool get hasCountdown => sectionKey == 'flash_sale' && endsAt != null;
}

List<Product> mergeDuplicateProducts(List<Product> products) {
  final grouped = <String, List<Product>>{};
  for (final product in products) {
    final key = [
      product.categoryId.trim().toLowerCase(),
      product.brand.trim().toLowerCase(),
      product.name.trim().toLowerCase(),
    ].join('|');
    grouped.putIfAbsent(key, () => []).add(product);
  }

  return grouped.values.map((group) {
    if (group.length == 1) return group.first;
    final variants = <ProductVariant>[];
    for (final product in group) {
      final ownVariants = product.variants ?? const <ProductVariant>[];
      if (ownVariants.isNotEmpty) {
        variants.addAll(ownVariants);
      } else {
        variants.add(
          ProductVariant(
            productId: product.id,
            size: product.size,
            pack: product.pack,
            mrp: product.mrp,
            buyPrice: product.buyPrice,
            stock: product.stock,
          ),
        );
      }
    }
    variants.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
    final cheapest = variants.first;
    final primary = group.firstWhere(
      (p) => p.id == cheapest.productId,
      orElse: () => group.first,
    );
    return Product(
      id: primary.id,
      categoryId: primary.categoryId,
      name: primary.name,
      brand: primary.brand,
      size: cheapest.size,
      pack: cheapest.pack,
      image: primary.image,
      description: primary.description,
      mrp: cheapest.mrp,
      buyPrice: cheapest.buyPrice,
      stock: variants.fold<int>(0, (sum, v) => sum + (v.stock ?? 0)),
      variants: variants,
    );
  }).toList();
}

final class DeliveryLocationQuery {
  const DeliveryLocationQuery({
    this.area = '',
    this.city = '',
    this.pincode = '',
  });

  final String area;
  final String city;
  final String pincode;

  @override
  bool operator ==(Object other) {
    return other is DeliveryLocationQuery &&
        other.area == area &&
        other.city == city &&
        other.pincode == pincode;
  }

  @override
  int get hashCode => Object.hash(area, city, pincode);
}

final class DeliveryContext {
  const DeliveryContext({
    required this.area,
    required this.etaMinutes,
    required this.etaLabel,
    required this.matched,
    required this.serviceable,
    this.deliveryFee,
    this.freeDeliveryMinOrder,
    this.fallbackText,
  });

  final String area;
  final int etaMinutes;
  final String etaLabel;
  final bool matched;
  final bool serviceable;
  final double? deliveryFee;
  final double? freeDeliveryMinOrder;
  final String? fallbackText;

  factory DeliveryContext.fromJson(Map<String, dynamic> json) {
    return DeliveryContext(
      area: json['area']?.toString() ?? 'your area',
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ??
          (json['eta_minutes'] as num?)?.toInt() ??
          120,
      etaLabel: json['etaLabel']?.toString() ??
          json['eta_label']?.toString() ??
          'standard time',
      matched: json['matched'] == true,
      serviceable: json['serviceable'] == true || json['matched'] == true,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ??
          (json['delivery_fee'] as num?)?.toDouble(),
      freeDeliveryMinOrder:
          (json['freeDeliveryMinOrder'] as num?)?.toDouble() ??
              (json['free_delivery_min_order'] as num?)?.toDouble(),
      fallbackText:
          json['fallbackText']?.toString() ?? json['fallback_text']?.toString(),
    );
  }

  String get deliveryText => serviceable
      ? 'Delivery in $etaLabel'
      : (fallbackText ?? 'Not currently serviceable in $area');
}
