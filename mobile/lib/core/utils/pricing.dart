import 'dart:math' as math;

class PricingBreakdown {
  const PricingBreakdown({
    required this.mrpPerPiece,
    required this.packSize,
    required this.discountPercent,
    required this.originalTotalPrice,
    required this.discountedTotalPrice,
    required this.perPiecePrice,
    required this.perPieceMargin,
    required this.totalMargin,
  });

  final double mrpPerPiece;
  final int packSize;
  final double discountPercent;
  final double originalTotalPrice;
  final double discountedTotalPrice;
  final double perPiecePrice;
  final double perPieceMargin;
  final double totalMargin;
}

int packUnitsFromLabel(String pack) {
  final normalized = pack.toLowerCase();
  final packMatch = RegExp(
    r'(?:pack|case|box|carton)\s*(?:of)?\s*(\d+)',
  ).firstMatch(normalized);
  final pieceMatch = RegExp(
    r'(\d+)\s*(?:pcs?|pieces?|piece|units?|bottles?|bars?|packs?)\b',
  ).firstMatch(normalized);
  final multiplyMatch = RegExp(r'(?:x|×)\s*(\d+)').firstMatch(normalized);
  return int.tryParse(
        packMatch?.group(1) ??
            pieceMatch?.group(1) ??
            multiplyMatch?.group(1) ??
            '1',
      ) ??
      1;
}

PricingBreakdown calculatePricing({
  required num mrp,
  required num sellingPrice,
  required int packSize,
}) {
  final safePackSize = math.max(1, packSize);
  final mrpPerPiece = mrp.toDouble();
  final originalTotal = mrpPerPiece * safePackSize;
  final discountedTotal = sellingPrice.toDouble();
  final perPiecePrice = discountedTotal / safePackSize;
  final perPieceMargin = mrpPerPiece - perPiecePrice;
  final topDownMargin = originalTotal - discountedTotal;
  final bottomUpMargin = perPieceMargin * safePackSize;

  assert(
    (topDownMargin - bottomUpMargin).abs() < 0.0001,
    'Pricing margin drift: top-down=$topDownMargin bottom-up=$bottomUpMargin',
  );

  final discountPercent = originalTotal <= 0
      ? 0.0
      : ((originalTotal - discountedTotal) / originalTotal) * 100;

  return PricingBreakdown(
    mrpPerPiece: mrpPerPiece,
    packSize: safePackSize,
    discountPercent: discountPercent,
    originalTotalPrice: originalTotal,
    discountedTotalPrice: discountedTotal,
    perPiecePrice: perPiecePrice,
    perPieceMargin: perPieceMargin,
    totalMargin: bottomUpMargin,
  );
}

String compactPrice(num value, {int maxDecimals = 1}) {
  final fixed = value.toStringAsFixed(maxDecimals);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
