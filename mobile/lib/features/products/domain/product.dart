import '../../../core/utils/pricing.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.image,
    required this.tintHex,
  });
  final String id, name, image, tintHex;
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.size,
    required this.pack,
    required this.image,
    required this.mrp,
    required this.buyPrice,
    required this.stock,
    this.description = '',
    this.variants,
  });
  final String id, categoryId, name, brand, size, pack, image;
  final String description;
  final num mrp, buyPrice;
  final int stock;
  final List<ProductVariant>? variants;
  double get margin => pricing.totalMargin;
  PricingBreakdown get pricing => calculatePricing(
        mrp: mrp,
        sellingPrice: buyPrice,
        packSize: packUnitsFromLabel(pack),
      );
}

class ProductVariant {
  const ProductVariant({
    required this.size,
    required this.pack,
    required this.mrp,
    required this.buyPrice,
    this.id,
    this.productId,
    this.stock,
    this.packQuantity,
    this.costPrice,
    this.isActive = true,
  });

  final String? id;
  final String? productId;
  final String size;
  final String pack;
  final num mrp;
  final num buyPrice;
  final int? stock;
  final int? packQuantity;
  final num? costPrice;
  final bool isActive;

  double get margin => pricing.totalMargin;
  PricingBreakdown get pricing => calculatePricing(
        mrp: mrp,
        sellingPrice: buyPrice,
        packSize: packUnits,
      );
  String get keyPart =>
      (id?.isNotEmpty == true ? id! : size).replaceAll(RegExp(r'\s+'), '_');
  int get packUnits {
    if (packQuantity != null && packQuantity! > 0) return packQuantity!;
    return packUnitsFromLabel(pack);
  }
}
