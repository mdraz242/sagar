import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/i18n/translations.dart';
import '../../core/utils/money.dart';
import '../../core/utils/pricing.dart';
import '../../features/cart/application/cart_provider.dart';
import '../../features/products/domain/product.dart';
import 'catalog_image.dart';

List<ProductVariant> _cardVariants(Product product) {
  final variants = product.variants ?? const <ProductVariant>[];
  if (variants.isNotEmpty) {
    final sorted = variants
        .where((variant) => variant.isActive && _hasValidVariantPrice(variant))
        .toList()
      ..sort((a, b) {
        final aStock = a.stock ?? product.stock;
        final bStock = b.stock ?? product.stock;
        if (aStock > 0 && bStock <= 0) return -1;
        if (aStock <= 0 && bStock > 0) return 1;
        final packCompare =
            _packUnitsFor(product, a).compareTo(_packUnitsFor(product, b));
        if (packCompare != 0) return packCompare;
        return a.buyPrice.compareTo(b.buyPrice);
      });
    if (sorted.isNotEmpty) return sorted;
  }
  if (!_isPositiveFinite(product.mrp) || !_isPositiveFinite(product.buyPrice)) {
    return const <ProductVariant>[];
  }
  return [
    ProductVariant(
      id: product.id,
      productId: product.id,
      size: product.size,
      pack: product.pack,
      mrp: product.mrp,
      buyPrice: product.buyPrice,
      stock: product.stock,
    ),
  ];
}

bool _isPositiveFinite(num value) => value.isFinite && value > 0;

bool _hasValidVariantPrice(ProductVariant variant) {
  return _isPositiveFinite(variant.mrp) && _isPositiveFinite(variant.buyPrice);
}

ProductVariant _displayVariant(Product product, List<ProductVariant> variants) {
  return variants.firstWhere(
    (variant) => (variant.stock ?? product.stock) > 0,
    orElse: () => variants.first,
  );
}

int _packUnitsFor(Product product, ProductVariant variant) {
  if (variant.packUnits > 1) return variant.packUnits;
  final labels = [
    variant.pack,
    variant.size,
    product.pack,
    product.size,
    product.description,
    product.name,
  ];
  for (final label in labels) {
    final units = packUnitsFromLabel(label);
    if (units > 1) return units;
  }
  return 1;
}

PricingBreakdown _pricingFor(Product product, ProductVariant variant) {
  return calculatePricing(
    mrp: variant.mrp,
    sellingPrice: variant.buyPrice,
    packSize: _packUnitsFor(product, variant),
  );
}

String _unitLabelFor(Product product, ProductVariant variant) {
  final raw = variant.pack.trim().isNotEmpty
      ? variant.pack.trim()
      : product.pack.trim().isNotEmpty
          ? product.pack.trim()
          : 'pcs';
  if (raw.length <= 6 && RegExp(r'^[a-zA-Z]+$').hasMatch(raw)) {
    return raw.toLowerCase();
  }
  final normalized = raw.toLowerCase();
  if (normalized.contains('kg')) return 'kg';
  if (normalized.contains('ml')) return 'ml';
  if (normalized.contains('ltr') || normalized.contains('litre')) return 'ltr';
  if (normalized.contains('l')) return 'l';
  if (normalized.contains('gm') || normalized.contains('gram')) return 'gm';
  if (normalized.contains('g')) return 'g';
  return 'pcs';
}

String _unitMrpText(Product product, ProductVariant variant) {
  return 'MRP Rs ${compactPrice(variant.mrp, maxDecimals: 2)}/${_unitLabelFor(product, variant)}';
}

void showProductVariantPicker(BuildContext context, Product product) {
  final variants = _cardVariants(product);
  if (variants.isEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('This product is currently unavailable.')),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _VariantPickerSheet(product: product, variants: variants),
  );
}

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final variants = _cardVariants(product);
    if (variants.isEmpty) {
      return _UnavailableProductCard(product: product);
    }
    final displayVariant = _displayVariant(product, variants);
    final hasVariants = variants.length > 1;
    final inStock =
        variants.any((variant) => (variant.stock ?? product.stock) > 0);
    final cart = ref.watch(cartProvider);
    final pricing = _pricingFor(product, displayVariant);
    final unitMrpText = _unitMrpText(product, displayVariant);
    final quantityKeys = {
      if (variants.isEmpty) product.id,
      ...variants.map((variant) => variantCartKey(product, variant)),
    };
    final qty = quantityKeys.fold<int>(
      0,
      (sum, key) => sum + (cart[key] ?? 0),
    );
    final singleCartKey =
        variants.isEmpty ? product.id : variantCartKey(product, displayVariant);
    return LayoutBuilder(builder: (context, constraints) {
      final width =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 170.0;
      final height = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : double.infinity;
      final compact = width < 156 || height < 360;
      final imageHeight = (width * .95).clamp(130.0, 170.0);
      final bodyPad = compact ? 8.0 : 10.0;

      return Material(
        color: Colors.white,
        elevation: 2.5,
        shadowColor: AppColors.ink.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => hasVariants
              ? showProductVariantPicker(context, product)
              : context.push('/products/${product.id}'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE9EDF5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 8,
                        child: _tag(
                          unitMrpText,
                          AppColors.brightBlue,
                          compact: compact,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 8,
                        child: _tag(
                          '${pricing.discountPercent.round()}% off',
                          const Color(0xFF122B5F),
                          compact: compact,
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 12 : 14,
                            compact ? 30 : 34,
                            compact ? 12 : 14,
                            compact ? 22 : 24,
                          ),
                          child: CatalogImage(
                            product.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 8,
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 4 : 5,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: orangeGradient(),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            'PACK OF ${pricing.packSize}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 8.5 : 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(bodyPad, 2, bodyPad, bodyPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _infoChip(
                            unitMrpText,
                            compact: compact,
                          ),
                          _infoChip(
                            'Pack of ${pricing.packSize}',
                            compact: compact,
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 3 : 5),
                      SizedBox(
                        height: compact ? 24 : 28,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: compact ? 12.5 : 14,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '${hasVariants ? 'From ' : ''}${money(pricing.discountedTotalPrice)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: compact ? 15 : 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            money(pricing.originalTotalPrice),
                            style: TextStyle(
                              color: const Color(0xFF9EA3B0),
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 4 : 5),
                      _marginStrip(pricing, compact: compact),
                      SizedBox(height: compact ? 5 : 6),
                      !inStock
                          ? _stockBadge(compact: compact)
                          : qty == 0
                              ? _addButton(
                                  context,
                                  ref,
                                  lang,
                                  variants,
                                  compact: compact,
                                )
                              : hasVariants
                                  ? _variantQtyButton(context, qty, lang)
                                  : _qtyControl(ref, qty, singleCartKey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _addButton(
    BuildContext context,
    WidgetRef ref,
    Lang lang,
    List<ProductVariant> variants, {
    bool compact = false,
  }) {
    final hasVariants = variants.length > 1;
    return OutlinedButton(
      onPressed: () async {
        if (hasVariants) {
          _showProductSheet(context);
          return;
        }
        final key = variants.isEmpty
            ? product.id
            : variantCartKey(product, variants.first);
        await ref.read(cartProvider.notifier).add(key);
      },
      style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue),
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
              minimumSize: Size(0, compact ? 32 : 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99)))
          .copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? AppColors.orange
              : AppColors.blue,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.pressed)
                ? AppColors.orange
                : AppColors.blue,
          ),
        ),
        overlayColor: WidgetStateProperty.all(
          AppColors.orange.withValues(alpha: .08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ADD',
              style: TextStyle(
                  fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w900)),
          if (hasVariants)
            Text('${variants.length} ${tr('options', lang)}',
                style: TextStyle(
                    fontSize: compact ? 8 : 9,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _stockBadge({bool compact = false}) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: compact ? 7 : 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryAlt),
      ),
      child: Text(
        'Out of stock',
        style: TextStyle(
          color: AppColors.primaryAlt,
          fontSize: compact ? 10.5 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _variantQtyButton(BuildContext context, int qty, Lang lang) {
    return OutlinedButton(
      onPressed: () => _showProductSheet(context),
      style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
      child: Text('${tr('inCart', lang)}: $qty',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }

  Widget _qtyControl(WidgetRef ref, int qty, String cartKey) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.blue),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).add(cartKey, -1),
            icon: const Icon(Icons.remove),
            color: AppColors.blue,
            visualDensity: VisualDensity.compact,
            splashColor: AppColors.orange.withValues(alpha: .14),
            highlightColor: AppColors.orange.withValues(alpha: .08),
          ),
          Text('$qty',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppColors.blue)),
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).add(cartKey),
            icon: const Icon(Icons.add),
            color: AppColors.blue,
            visualDensity: VisualDensity.compact,
            splashColor: AppColors.orange.withValues(alpha: .14),
            highlightColor: AppColors.orange.withValues(alpha: .08),
          ),
        ],
      ),
    );
  }

  void _showProductSheet(BuildContext context) {
    showProductVariantPicker(context, product);
  }

  Widget _tag(String text, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 5, vertical: compact ? 2 : 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 7.5 : 9,
              fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoChip(String text, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE4EAF7)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.muted,
          fontSize: compact ? 8.5 : 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _marginStrip(PricingBreakdown pricing, {bool compact = false}) {
    if (pricing.totalMargin <= 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'Total margin ${money(pricing.totalMargin)}',
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.brightBlue,
          fontSize: compact ? 8.5 : 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UnavailableProductCard extends StatelessWidget {
  const _UnavailableProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppColors.ink.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE9EDF5)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Opacity(
                opacity: .55,
                child: CatalogImage(product.image, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F2),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.primaryAlt),
              ),
              child: const Text(
                'Currently unavailable',
                style: TextStyle(
                  color: AppColors.primaryAlt,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantPickerSheet extends ConsumerStatefulWidget {
  const _VariantPickerSheet({
    required this.product,
    required this.variants,
  });

  final Product product;
  final List<ProductVariant> variants;

  @override
  ConsumerState<_VariantPickerSheet> createState() =>
      _VariantPickerSheetState();
}

class _VariantPickerSheetState extends ConsumerState<_VariantPickerSheet> {
  late ProductVariant selected = widget.variants.first;
  int quantity = 1;

  int _savePercent(ProductVariant variant) {
    final active = widget.variants
        .where((item) => item.isActive && item.buyPrice > 0)
        .toList()
      ..sort(
        (a, b) => _packUnitsFor(widget.product, a).compareTo(
          _packUnitsFor(widget.product, b),
        ),
      );
    if (active.isEmpty) return marginPercent(variant.mrp, variant.buyPrice);
    final base = active.first;
    final basePerPiece =
        base.buyPrice / _packUnitsFor(widget.product, base).clamp(1, 999999);
    final variantPerPiece = variant.buyPrice /
        _packUnitsFor(widget.product, variant).clamp(1, 999999);
    if (basePerPiece <= 0 || variantPerPiece >= basePerPiece) {
      return marginPercent(variant.mrp, variant.buyPrice);
    }
    return (((basePerPiece - variantPerPiece) / basePerPiece) * 100).round();
  }

  Widget _header(bool inStock) {
    final pricing = _pricingFor(widget.product, selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EAF2)),
              ),
              child: CatalogImage(widget.product.image),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 15,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (widget.product.brand.isNotEmpty) widget.product.brand,
                      if (widget.product.categoryId.isNotEmpty)
                        widget.product.categoryId,
                    ].join('  -  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.blue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F7)),
          ),
          child: Row(
            children: [
              _headerMetric('MRP', money(pricing.originalTotalPrice)),
              _headerMetric('Price', money(selected.buyPrice)),
              Expanded(
                child: _headerMetric(
                  'Margin',
                  '${money(pricing.totalMargin)} (${marginPercent(selected.mrp, selected.buyPrice)}%)',
                  valueColor: AppColors.success,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: inStock
                  ? AppColors.success.withValues(alpha: .1)
                  : AppColors.primaryAlt.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              inStock ? 'In Stock' : 'Out of Stock',
              style: TextStyle(
                color: inStock ? AppColors.success : AppColors.primaryAlt,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerMetric(
    String label,
    String value, {
    Color valueColor = AppColors.ink,
    bool alignEnd = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityRow(int totalPieces) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                '$quantity pack${quantity == 1 ? '' : 's'} ($totalPieces pcs)',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        _SheetQtyButton(
          icon: Icons.remove,
          onTap: quantity <= 1 ? null : () => setState(() => quantity--),
        ),
        Container(
          width: 52,
          height: 40,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F7)),
          ),
          child: Text(
            '$quantity',
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _SheetQtyButton(
            icon: Icons.add, onTap: () => setState(() => quantity++)),
      ],
    );
  }

  Widget _totalBox(num totalPrice, num totalMargin, PricingBreakdown pricing) {
    final marginPercentText = pricing.originalTotalPrice > 0
        ? ' (${((pricing.totalMargin / pricing.originalTotalPrice) * 100).round()}%)'
        : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Total Price',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(totalPrice),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Est. margin ${money(totalMargin)}$marginPercentText',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPricing = _pricingFor(widget.product, selected);
    final selectedPackUnits = _packUnitsFor(widget.product, selected);
    final totalPieces = selectedPackUnits * quantity;
    final totalPrice = selected.buyPrice * quantity;
    final totalMargin = selectedPricing.totalMargin * quantity;
    final stock = selected.stock ?? widget.product.stock;
    final inStock = stock > 0;

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * .78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(inStock),
              const SizedBox(height: 16),
              const Text(
                'Select Pack Size',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.variants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final variant = widget.variants[index];
                    final active = variant.keyPart == selected.keyPart &&
                        variant.productId == selected.productId;
                    final variantPricing = _pricingFor(widget.product, variant);
                    final save = _savePercent(variant);
                    final available =
                        (variant.stock ?? widget.product.stock) > 0;
                    return InkWell(
                      onTap: available
                          ? () => setState(() {
                                selected = variant;
                                quantity = 1;
                              })
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary.withValues(alpha: .07)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? AppColors.primaryAlt
                                : const Color(0xFFE8ECF5),
                            width: active ? 1.4 : 1,
                          ),
                        ),
                        child: Opacity(
                          opacity: available ? 1 : .48,
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: active
                                    ? AppColors.primaryAlt
                                    : const Color(0xFFB8C0D4),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variant.size,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${variant.pack.isEmpty ? variant.size : variant.pack}  (${variantPricing.packSize} pcs)',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    money(variant.buyPrice),
                                    style: const TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    available
                                        ? (save > 0
                                            ? 'Save $save%'
                                            : 'Best price')
                                        : 'Out of Stock',
                                    style: TextStyle(
                                      color: available
                                          ? AppColors.primaryAlt
                                          : AppColors.primaryAlt,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                available ? 'In Stock' : 'Out',
                                style: TextStyle(
                                  color: available
                                      ? AppColors.success
                                      : AppColors.primaryAlt,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _quantityRow(totalPieces),
              const SizedBox(height: 12),
              _totalBox(totalPrice, totalMargin, selectedPricing),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: inStock
                    ? () async {
                        final cartKey =
                            variantCartKey(widget.product, selected);
                        await ref
                            .read(cartProvider.notifier)
                            .add(cartKey, quantity);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added to cart - ${widget.product.name} (${selected.size})',
                            ),
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () => context.go('/cart'),
                            ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAlt,
                  disabledBackgroundColor: const Color(0xFFE3E5EC),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetQtyButton extends StatelessWidget {
  const _SheetQtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFE6E8EE) : AppColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
