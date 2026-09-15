part of 'home_screen.dart';

class _BrandScroller extends StatelessWidget {
  const _BrandScroller({required this.brands, required this.products});
  final List<String> brands;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final brand = brands[index];
          final image =
              products.firstWhere((product) => product.brand == brand).image;
          return InkWell(
            onTap: () => context.go('/brands/${Uri.encodeComponent(brand)}'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 86,
              padding: const EdgeInsets.all(8),
              decoration: _softCard(radius: 12),
              child: Column(
                children: [
                  Expanded(child: CatalogImage(image)),
                  Text(brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WhyGrid extends StatelessWidget {
  const _WhyGrid({required this.area, required this.serviceable});

  final String area;
  final bool serviceable;

  @override
  Widget build(BuildContext context) {
    final location = area == 'Area pending' ? 'your area' : area;
    final items = [
      (
        Icons.location_on_outlined,
        serviceable
            ? 'Delivered\nAcross $location'
            : 'Not serviceable\nin $location'
      ),
      (Icons.shield_outlined, 'Safe &\nHygienic'),
      (Icons.sell_outlined, 'Best Prices\nGuaranteed'),
      (Icons.headset_mic_outlined, '24x7\nSupport'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _softCard(radius: 14),
            child: Row(
              children: [
                Icon(item.$1, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.$2,
                      style: const TextStyle(
                          height: 1.15,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Address? _homeDefaultAddress(List<Address>? addresses) {
  if (addresses == null || addresses.isEmpty) return null;
  final defaults = addresses.where((address) => address.isDefault);
  return defaults.isNotEmpty ? defaults.first : addresses.first;
}

String _homeDeliveryArea(ShopProfile? shop, dynamic address) {
  final parts = [
    address?.city,
    address?.area,
    address?.line1,
    shop?.area,
    shop?.address,
  ];
  for (final part in parts) {
    final value = part?.toString().trim() ?? '';
    if (value.isNotEmpty &&
        value != 'Area pending' &&
        value != 'Address pending') {
      return value;
    }
  }
  return 'Area pending';
}

DeliveryLocationQuery _homeDeliveryQuery(ShopProfile? shop, Address? address) {
  final area = _homeDeliveryArea(shop, address);
  final city = address?.city.trim() ?? '';
  final pincode = (address?.pincode.trim().isNotEmpty == true
          ? address!.pincode.trim()
          : shop?.pincode.trim()) ??
      '';
  return DeliveryLocationQuery(
    area: area == 'Area pending' ? '' : area,
    city: city,
    pincode: pincode,
  );
}

BoxDecoration _softCard({double radius = 18}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE8EAF2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .045),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

List<Product> _topDeals(List<Product> products) {
  return [...products]..sort((a, b) => b.margin.compareTo(a.margin));
}

List<String> _brands(List<Product> products) {
  return products
      .map((product) => product.brand)
      .where((brand) => brand.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

List<Product> _filterProducts(List<Product> products, String query) {
  if (query.isEmpty) return const [];
  final normalized = query.toLowerCase();
  return products.where((product) {
    return product.name.toLowerCase().contains(normalized) ||
        product.brand.toLowerCase().contains(normalized) ||
        product.size.toLowerCase().contains(normalized) ||
        product.pack.toLowerCase().contains(normalized);
  }).toList();
}

List<Category> _filterCategories(List<Category> categories, String query) {
  if (query.isEmpty) return const [];
  final normalized = query.toLowerCase();
  return categories
      .where((category) => category.name.toLowerCase().contains(normalized))
      .toList();
}

List<_SearchSuggestion> _suggestions(dynamic snapshot, String query) {
  if (query.isEmpty) return const [];
  final categoryById = {
    for (final Category category in snapshot.categories) category.id: category,
  };
  final productSuggestions =
      _filterProducts(snapshot.products, query).take(6).map((product) {
    final category = categoryById[product.categoryId];
    return _SearchSuggestion(
      title: product.name,
      subtitle: category == null ? product.brand : 'in ${category.name}',
      image: product.image,
      route: '/products/${product.id}',
      isCategory: false,
    );
  });
  final categorySuggestions = _filterCategories(snapshot.categories, query)
      .take(4)
      .map((category) => _SearchSuggestion(
            title: category.name,
            subtitle: 'Category',
            image: category.image,
            route: '/category/${category.id}',
            isCategory: true,
          ));
  return [...productSuggestions, ...categorySuggestions].take(8).toList();
}

String _copy(Lang lang, String en, String hi) => lang == Lang.hi ? hi : en;
