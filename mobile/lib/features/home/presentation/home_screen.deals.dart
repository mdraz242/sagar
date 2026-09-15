part of 'home_screen.dart';

class _DealsRow extends StatelessWidget {
  const _DealsRow({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 226,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => _DealCard(product: products[index]),
      ),
    );
  }
}

class _DealCard extends ConsumerWidget {
  const _DealCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = _dealVariants(product);
    final displayVariant = _dealDisplayVariant(product, variants);
    final pricing = _dealPricing(product, displayVariant);
    final hasVariants = variants.length > 1;
    final cartKey = variantCartKey(product, displayVariant);
    final cart = ref.watch(cartProvider);
    final quantityKeys = {
      product.id,
      ...variants.map((variant) => variantCartKey(product, variant)),
    };
    final qty = quantityKeys.fold<int>(
      0,
      (sum, key) => sum + (cart[key] ?? 0),
    );
    final inStock =
        variants.any((variant) => (variant.stock ?? product.stock) > 0);
    return InkWell(
      onTap: () => hasVariants
          ? showProductVariantPicker(context, product)
          : context.go('/products/${product.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 144,
        decoration: _softCard(radius: 14),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pricing.discountPercent.round()}% OFF',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(
                    height: 78,
                    child: Center(child: CatalogImage(product.image)),
                  ),
                  if (qty > 0) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Added x$qty',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.08,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(displayVariant.size,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Text(
                          '${hasVariants ? 'From ' : ''}${money(pricing.discountedTotalPrice)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      Text(money(pricing.originalTotalPrice),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total margin ${money(pricing.totalMargin)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.brightBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 3,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _DealQtyControl(
                product: product,
                cartKey: cartKey,
                qty: qty,
                inStock: inStock,
                hasVariants: hasVariants,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ProductVariant> _dealVariants(Product product) {
  final raw = product.variants ?? const <ProductVariant>[];
  if (raw.isEmpty) {
    return [
      ProductVariant(
        productId: product.id,
        size: product.size,
        pack: product.pack,
        mrp: product.mrp,
        buyPrice: product.buyPrice,
        stock: product.stock,
      ),
    ];
  }

  final sorted = raw.where((variant) => variant.isActive).toList()
    ..sort((a, b) {
      final aStock = a.stock ?? product.stock;
      final bStock = b.stock ?? product.stock;
      if (aStock > 0 && bStock <= 0) return -1;
      if (aStock <= 0 && bStock > 0) return 1;
      return a.buyPrice.compareTo(b.buyPrice);
    });
  if (sorted.isNotEmpty) return sorted;
  return [
    ProductVariant(
      productId: product.id,
      size: product.size,
      pack: product.pack,
      mrp: product.mrp,
      buyPrice: product.buyPrice,
      stock: product.stock,
    ),
  ];
}

ProductVariant _dealDisplayVariant(
  Product product,
  List<ProductVariant> variants,
) {
  if (variants.isEmpty) {
    return ProductVariant(
      productId: product.id,
      size: product.size,
      pack: product.pack,
      mrp: product.mrp,
      buyPrice: product.buyPrice,
      stock: product.stock,
    );
  }

  return variants.firstWhere(
    (variant) => variant.size == product.size && variant.pack == product.pack,
    orElse: () => variants.first,
  );
}

PricingBreakdown _dealPricing(Product product, ProductVariant variant) {
  if (variant.packUnits > 1) {
    return calculatePricing(
      mrp: variant.mrp,
      sellingPrice: variant.buyPrice,
      packSize: variant.packUnits,
    );
  }
  final labels = [
    variant.pack,
    variant.size,
    product.pack,
    product.size,
    product.description,
    product.name,
  ];
  final packSize = labels
      .map(packUnitsFromLabel)
      .firstWhere((units) => units > 1, orElse: () => 1);

  return calculatePricing(
    mrp: variant.mrp,
    sellingPrice: variant.buyPrice,
    packSize: packSize,
  );
}

class _DealQtyControl extends ConsumerWidget {
  const _DealQtyControl({
    required this.product,
    required this.cartKey,
    required this.qty,
    required this.inStock,
    required this.hasVariants,
  });

  final Product product;
  final String cartKey;
  final int qty;
  final bool inStock;
  final bool hasVariants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!inStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryAlt),
        ),
        child: const Text(
          'Out',
          style: TextStyle(
            color: AppColors.primaryAlt,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (qty == 0) {
      return InkWell(
        onTap: () async {
          if (hasVariants) {
            showProductVariantPicker(context, product);
            return;
          }
          await ref.read(cartProvider.notifier).add(cartKey);
          if (context.mounted) {
            showVyparToast(
              context,
              '${product.name} added to cart. Cart updated below.',
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.orange.withValues(alpha: .14),
        highlightColor: AppColors.orange.withValues(alpha: .08),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.blue, width: 1.4),
          ),
          child: const Icon(Icons.add, color: AppColors.blue, size: 18),
        ),
      );
    }

    return AnimatedScale(
      scale: 1.02,
      duration: const Duration(milliseconds: 160),
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.blue, width: 1.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: .12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DealQtyButton(
              icon: Icons.remove,
              onTap: hasVariants
                  ? () => showProductVariantPicker(context, product)
                  : () => ref.read(cartProvider.notifier).add(cartKey, -1),
            ),
            SizedBox(
              width: 22,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _DealQtyButton(
              icon: Icons.add,
              onTap: hasVariants
                  ? () => showProductVariantPicker(context, product)
                  : () => ref.read(cartProvider.notifier).add(cartKey),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealQtyButton extends StatelessWidget {
  const _DealQtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 28,
        height: 30,
        child: Icon(icon, color: AppColors.blue, size: 15),
      ),
    );
  }
}

class _BulkBanner extends StatelessWidget {
  const _BulkBanner({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// Background banner
          Opacity(
            opacity: .8,
            child: Image.asset(
              "assets/images/banner.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Optional dark overlay for text readability
          Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),

          /// Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bulk Order?\nBigger Savings!',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.05,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => context.go('/bulk-order'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.blue,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Order Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
