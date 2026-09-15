import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../cart/application/cart_provider.dart';
import '../domain/product.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return AppShell(
      showHeader: false,
      child: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (product) {
          if (product == null) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: VyparEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product not found',
                  subtitle: 'This product may have been removed.',
                  actionLabel: 'Browse products',
                  onAction: () => context.go('/category'),
                ),
              ),
            );
          }
          final relatedAsync =
              ref.watch(productsByCategoryProvider(product.categoryId));
          final related = (relatedAsync.valueOrNull ?? const <Product>[])
              .where((item) =>
                  item.categoryId == product.categoryId &&
                  item.id != product.id)
              .take(6)
              .toList();
          final units = _units(product.pack);
          final hasVariants = (product.variants?.length ?? 0) > 1;
          final cart = ref.watch(cartProvider);
          final qty = hasVariants
              ? product.variants!.fold<int>(
                  0,
                  (sum, variant) =>
                      sum + (cart[variantCartKey(product, variant)] ?? 0),
                )
              : cart[product.id] ?? 0;
          final inStock = product.stock > 0;

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _safeBack(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.blue,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => showVyparToast(
                          context,
                          'Added to wishlist.',
                        ),
                        icon: const Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                    children: [
                      VyparCard(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 230,
                              child: CatalogImage(product.image),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Container(
                                    width: i == 0 ? 18 : 7,
                                    height: 7,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: i == 0
                                          ? AppColors.primaryAlt
                                          : AppColors.border,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        product.brand.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryAlt,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${product.size} - ${product.pack}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!inStock) ...[
                        VyparCard(
                          color: const Color(0xFFFFF5F2),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.primaryAlt),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This item is out of stock right now.',
                                  style: TextStyle(
                                    color: AppColors.primaryAlt,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      VyparCard(
                        color: const Color(0xFFF6F8FF),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${hasVariants ? 'From ' : ''}${money(product.buyPrice)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  money(product.mrp),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const Spacer(),
                                _Badge(
                                  '${marginPercent(product.mrp, product.buyPrice)}% OFF',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$units pcs - ${money((product.buyPrice / units).round())}/pc',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Retailer margin ${money(product.margin)} per pack',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${product.name} is available for fast B2B delivery with bulk pack pricing, margin visibility, and reliable stock updates.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reviews',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      VyparCard(
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 28),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '4.6 average from VyparHub retailers',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/profile/rate'),
                              child: const Text('Rate'),
                            ),
                          ],
                        ),
                      ),
                      if (related.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const VyparSectionHeader(title: 'Related Products'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 330,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: related.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) => SizedBox(
                              width: 176,
                              child: ProductCard(product: related[index]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    MediaQuery.paddingOf(context).bottom + 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: !inStock
                            ? VyparButton.ghost(
                                label: 'Out of Stock',
                                icon: Icons.inventory_2_outlined,
                                onPressed: null,
                              )
                            : qty == 0
                                ? VyparButton.ghost(
                                    label: 'Add to Cart',
                                    icon: Icons.add_shopping_cart,
                                    onPressed: () => hasVariants
                                        ? showProductVariantPicker(
                                            context,
                                            product,
                                          )
                                        : ref
                                            .read(cartProvider.notifier)
                                            .add(product.id),
                                  )
                                : hasVariants
                                    ? VyparButton.ghost(
                                        label: 'In Cart: $qty',
                                        icon: Icons.shopping_cart_checkout,
                                        onPressed: () =>
                                            showProductVariantPicker(
                                          context,
                                          product,
                                        ),
                                      )
                                    : _QtyControl(product: product),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: VyparButton.primary(
                          label: 'Order Now',
                          icon: Icons.flash_on,
                          onPressed: inStock
                              ? () async {
                                  if (qty == 0) {
                                    if (hasVariants) {
                                      showProductVariantPicker(
                                        context,
                                        product,
                                      );
                                      return;
                                    }
                                    await ref
                                        .read(cartProvider.notifier)
                                        .add(product.id);
                                  }
                                  if (context.mounted) context.go('/checkout');
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _units(String pack) {
    final match = RegExp(r'(\d+)').firstMatch(pack);
    return int.tryParse(match?.group(1) ?? '1') ?? 1;
  }
}

class _QtyControl extends ConsumerWidget {
  const _QtyControl({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider)[product.id] ?? 0;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryAlt),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () =>
                ref.read(cartProvider.notifier).add(product.id, -1),
            icon: const Icon(Icons.remove, color: AppColors.primaryAlt),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: AppColors.primaryAlt,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).add(product.id),
            icon: const Icon(Icons.add, color: AppColors.primaryAlt),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

void _safeBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/category');
  }
}
