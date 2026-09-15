import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../domain/product.dart';

class BrandsScreen extends ConsumerWidget {
  const BrandsScreen({super.key, this.brandName});
  final String? brandName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (brandName != null) {
      return _BrandDetail(brand: Uri.decodeComponent(brandName!));
    }
    final catalog = ref.watch(catalogSnapshotProvider);
    return AppShell(
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (snapshot) {
          final brandList = _brands(snapshot.products);
          return LayoutBuilder(
            builder: (context, constraints) {
              final pad = Responsive.horizontalPadding(constraints);
              return ListView(
                padding: EdgeInsets.all(pad),
                children: [
                  Row(children: [
                    IconButton(
                        onPressed: () => goBackOr(context, '/'),
                        icon: const Icon(Icons.arrow_back)),
                    const Expanded(
                        child: Text('Top FMCG Brands',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900))),
                  ]),
                  const Text('Tap any brand to see all products',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: Responsive.categoryColumns(constraints)
                        .clamp(3, 6)
                        .toInt(),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: brandList.map((brand) {
                      final products =
                          _productsByBrand(snapshot.products, brand);
                      return InkWell(
                        onTap: () =>
                            context.go('/brands/${Uri.encodeComponent(brand)}'),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: const Color(0xFFE6E8EE))),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Expanded(
                                  child: products.isEmpty
                                      ? const Icon(Icons.store)
                                      : CatalogImage(
                                          products.first.image,
                                          fit: BoxFit.contain,
                                        )),
                              Text(brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: _brandColor(brand),
                                      fontWeight: FontWeight.w900)),
                              Text('${products.length} products',
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _brandColor(String brand) {
    const colors = [
      AppColors.blue,
      AppColors.orange,
      AppColors.success,
      Color(0xFF5E35B1),
      Color(0xFFC2185B)
    ];
    return colors[brand.hashCode.abs() % colors.length];
  }
}

class _BrandDetail extends ConsumerWidget {
  const _BrandDetail({required this.brand});
  final String brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogSnapshotProvider);
    return AppShell(
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (snapshot) {
          final products = _productsByBrand(snapshot.products, brand);
          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  IconButton(
                      onPressed: () => goBackOr(context, '/brands'),
                      icon: const Icon(Icons.arrow_back)),
                  Expanded(
                      child: Text(brand,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900))),
                  Text('${products.length} items',
                      style: const TextStyle(
                          color: AppColors.muted, fontWeight: FontWeight.w700)),
                ]),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(constraints),
                      mainAxisExtent: constraints.maxWidth < 380 ? 344 : 360,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) =>
                        ProductCard(product: products[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<String> _brands(List<Product> products) {
  return products
      .map((p) => p.brand)
      .where((b) => b.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

List<Product> _productsByBrand(List<Product> products, String brand) {
  return products
      .where((p) => p.brand.toLowerCase() == brand.toLowerCase())
      .toList();
}
