String money(num value) =>
    'Rs ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
int marginPercent(num mrp, num buy) =>
    mrp == 0 ? 0 : (((mrp - buy) / mrp) * 100).round();
