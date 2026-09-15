import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/api_services.dart';
import '../../../core/utils/pricing.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../products/domain/product.dart';

final cartErrorProvider = StateProvider<String?>((_) => null);

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, int>>(
  (ref) => CartNotifier(ref),
);

class CartNotifier extends StateNotifier<Map<String, int>> {
  CartNotifier(this.ref) : super({});

  final Ref ref;

  Future<void> loadFromServer() async {
    if (AppConfig.useMockData) return;
    try {
      state = _canonicalizeCart(await ref.read(cartApiProvider).getCart());
      ref.read(cartErrorProvider.notifier).state = null;
    } catch (error) {
      ref.read(cartErrorProvider.notifier).state = apiErrorMessage(error);
    }
  }

  Future<void> add(String id, [int qty = 1]) async {
    if (qty == 0) return;

    final before = {...state};
    final next = {...state};
    final cartKey = _canonicalCartKey(id);
    next[cartKey] = (next[cartKey] ?? 0) + qty;
    if ((next[cartKey] ?? 0) <= 0) next.remove(cartKey);
    state = _canonicalizeCart(next);

    if (AppConfig.useMockData) return;

    try {
      state = _canonicalizeCart(
        qty > 0
            ? await ref.read(cartApiProvider).add(cartKey, qty)
            : await ref.read(cartApiProvider).remove(cartKey, qty.abs()),
      );
      ref.read(cartErrorProvider.notifier).state = null;
    } catch (error) {
      state = before;
      ref.read(cartErrorProvider.notifier).state = apiErrorMessage(error);
    }
  }

  Future<void> remove(String id) async {
    final cartKey = _canonicalCartKey(id);
    final qty = state[cartKey] ?? 0;
    final before = {...state};
    state = _canonicalizeCart({...state}..remove(cartKey));

    if (AppConfig.useMockData || qty == 0) return;

    try {
      state = _canonicalizeCart(
          await ref.read(cartApiProvider).remove(cartKey, qty));
      ref.read(cartErrorProvider.notifier).state = null;
    } catch (error) {
      state = before;
      ref.read(cartErrorProvider.notifier).state = apiErrorMessage(error);
    }
  }

  Future<void> removeAll(Iterable<String> ids) async {
    for (final id in ids.toSet()) {
      await remove(id);
    }
  }

  void clear() => state = {};

  String _canonicalCartKey(String key) {
    final catalog = ref.read(catalogSnapshotProvider).valueOrNull;
    return canonicalCartKey(key, catalog?.products ?? const []);
  }

  Map<String, int> _canonicalizeCart(Map<String, int> cart) {
    final catalog = ref.read(catalogSnapshotProvider).valueOrNull;
    return canonicalizeCart(cart, catalog?.products ?? const []);
  }
}

class CartLine {
  CartLine(this.product, this.qty, this.cartKey, [this.variant]);

  final Product product;
  final ProductVariant? variant;
  final int qty;
  final String cartKey;

  String get title => product.name;
  String get subtitle =>
      variant == null ? product.size : '${variant!.size} - ${variant!.pack}';
  num get mrp => variant?.mrp ?? product.mrp;
  num get buyPrice => variant?.buyPrice ?? product.buyPrice;
  double get margin => calculatePricing(
        mrp: mrp,
        sellingPrice: buyPrice,
        packSize: variant?.packUnits ?? packUnitsFromLabel(product.pack),
      ).totalMargin;
}

class UnavailableCartLine {
  const UnavailableCartLine({
    required this.cartKey,
    required this.qty,
    required this.reason,
    this.productName,
  });

  final String cartKey;
  final int qty;
  final String reason;
  final String? productName;

  String get title => productName ?? 'Unavailable product';
}

class CartItemAvailability {
  const CartItemAvailability({
    required this.cartKey,
    required this.qty,
    required this.isAvailable,
    this.product,
    this.variant,
    this.reason,
    this.shouldCleanup = false,
  });

  final String cartKey;
  final int qty;
  final bool isAvailable;
  final Product? product;
  final ProductVariant? variant;
  final String? reason;
  final bool shouldCleanup;
}

String variantCartKey(Product product, ProductVariant variant) {
  final activeVariants = _activeVariants(product);
  if (activeVariants.length <= 1) return product.id;
  return '${product.id}__${variant.keyPart}';
}

String canonicalCartKey(String key, List<Product> products) {
  final parsed = parseCartKey(key);
  final product = _productForParsedKey(parsed, products);
  if (product == null) return key;

  final activeVariants = _activeVariants(product);
  if (activeVariants.length <= 1) return product.id;

  if (parsed.variantKey == null) {
    final fallback = _defaultVariant(product);
    return fallback == null ? product.id : variantCartKey(product, fallback);
  }

  final match = _variantForParsedKey(parsed, product);
  if (match == null) return key;
  return variantCartKey(product, match);
}

Map<String, int> canonicalizeCart(
    Map<String, int> cart, List<Product> products) {
  final next = <String, int>{};
  for (final entry in cart.entries) {
    if (entry.value <= 0) continue;
    final key = canonicalCartKey(entry.key, products);
    next[key] = (next[key] ?? 0) + entry.value;
  }
  return next;
}

Product? _productForParsedKey(ParsedCartKey parsed, List<Product> products) {
  for (final product in products) {
    if (product.id == parsed.productId) return product;
    final variants = product.variants ?? const <ProductVariant>[];
    if (variants.any((variant) => variant.productId == parsed.productId)) {
      return product;
    }
  }
  return null;
}

List<ProductVariant> _activeVariants(Product product) {
  return (product.variants ?? const <ProductVariant>[])
      .where((item) => item.isActive)
      .toList();
}

ProductVariant? _defaultVariant(Product product) {
  final variants = _activeVariants(product);
  if (variants.isEmpty) return null;
  return variants.firstWhere(
    (variant) => (variant.stock ?? 0) > 0,
    orElse: () => variants.first,
  );
}

ProductVariant? _variantForParsedKey(ParsedCartKey parsed, Product product) {
  final variants = _activeVariants(product);
  if (parsed.variantKey == null) {
    return _defaultVariant(product);
  }
  final normalizedVariantKey = _normalizeCartKeyPart(parsed.variantKey!);
  for (final variant in variants) {
    if (variant.productId == parsed.productId && variant.id == null) {
      return variant;
    }
    final variantKeys = [
      variant.keyPart,
      if (variant.id != null) variant.id!,
      variant.size,
      variant.pack,
      '${variant.size}_${variant.pack}',
    ].map(_normalizeCartKeyPart);
    if (variantKeys.contains(normalizedVariantKey)) {
      return variant;
    }
  }
  return null;
}

String _normalizeCartKeyPart(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

CartItemAvailability validateCartItemAvailability(
  MapEntry<String, int> entry,
  List<Product> products,
) {
  // Single cart validation path used by cart, checkout, and cleanup actions.
  final canonicalKey = canonicalCartKey(entry.key, products);
  final parsed = parseCartKey(canonicalKey);
  final product = _productForParsedKey(parsed, products);
  if (product == null) {
    return CartItemAvailability(
      cartKey: entry.key,
      qty: entry.value,
      isAvailable: false,
      reason: 'Removed',
      shouldCleanup: true,
    );
  }

  final variant = _variantForParsedKey(parsed, product);
  if (parsed.variantKey != null &&
      variant == null &&
      canonicalKey == entry.key) {
    return CartItemAvailability(
      cartKey: entry.key,
      qty: entry.value,
      isAvailable: false,
      product: product,
      reason: 'Pack removed',
      shouldCleanup: true,
    );
  }

  final stock = variant?.stock ?? product.stock;
  if (stock <= 0) {
    return CartItemAvailability(
      cartKey: entry.key,
      qty: entry.value,
      isAvailable: false,
      product: product,
      variant: variant,
      reason: 'Out of Stock',
    );
  }

  final cartKey =
      variant == null ? product.id : variantCartKey(product, variant);
  return CartItemAvailability(
    cartKey: cartKey,
    qty: entry.value,
    isAvailable: true,
    product: product,
    variant: variant,
  );
}

CartLine? _lineFromEntry(
  MapEntry<String, int> entry,
  List<Product> products,
) {
  final availability = validateCartItemAvailability(entry, products);
  if (!availability.isAvailable || availability.product == null) return null;
  return CartLine(
    availability.product!,
    entry.value,
    availability.cartKey,
    availability.variant,
  );
}

UnavailableCartLine? _unavailableLineFromEntry(
  MapEntry<String, int> entry,
  List<Product> products,
) {
  final availability = validateCartItemAvailability(entry, products);
  if (availability.isAvailable) return null;
  return UnavailableCartLine(
    cartKey: entry.key,
    qty: entry.value,
    productName: availability.product?.name,
    reason: _availabilityMessage(availability.reason),
  );
}

String _availabilityMessage(String? reason) {
  return switch (reason) {
    'Removed' => 'Removed',
    'Pack removed' => 'Pack size removed',
    'Out of Stock' => 'Out of Stock',
    _ => 'Unavailable',
  };
}

List<CartLine> cartLines(Map<String, int> cart, List<Product> products) {
  return canonicalizeCart(cart, products)
      .entries
      .map((entry) => _lineFromEntry(entry, products))
      .whereType<CartLine>()
      .toList();
}

List<UnavailableCartLine> unavailableCartLines(
  Map<String, int> cart,
  List<Product> products,
) {
  if (products.isEmpty) return const [];
  return canonicalizeCart(cart, products)
      .entries
      .map((entry) => _unavailableLineFromEntry(entry, products))
      .whereType<UnavailableCartLine>()
      .toList();
}

num cartBuy(Map<String, int> cart, List<Product> products) {
  return cartLines(cart, products).fold(0, (s, l) => s + l.buyPrice * l.qty);
}

num cartMrp(Map<String, int> cart, List<Product> products) {
  return cartLines(cart, products).fold(0, (s, l) => s + l.mrp * l.qty);
}

final cartLinesProvider = Provider<List<CartLine>>((ref) {
  final cart = ref.watch(cartProvider);
  final catalog = ref.watch(catalogSnapshotProvider).valueOrNull;
  return cartLines(cart, catalog?.products ?? const []);
});

final unavailableCartLinesProvider = Provider<List<UnavailableCartLine>>((ref) {
  final cart = ref.watch(cartProvider);
  final catalog = ref.watch(catalogSnapshotProvider).valueOrNull;
  return unavailableCartLines(cart, catalog?.products ?? const []);
});
