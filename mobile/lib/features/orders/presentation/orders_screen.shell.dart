part of 'orders_screen.dart';

class _OrderSubShell extends StatelessWidget {
  const _OrderSubShell({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => goBackOr(context, '/'),
                    icon: const Icon(Icons.arrow_back, color: AppColors.blue),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  action ?? const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

List<OrderSummary> _demoOrders() {
  return [
    OrderSummary(
      id: 'VH123456',
      status: 'Delivered',
      total: 205,
      createdAt: DateTime(2025, 5, 12, 10, 30),
      itemCount: 3,
      items: const [
        OrderItemSnapshot(
          id: 'demo-1',
          productId: 'demo-coke',
          quantity: 1,
          mrp: 58,
          buyPrice: 45,
          name: 'Coca Cola 750ml',
          imageUrl: 'products/coca-cola.jpg',
          size: '750ml',
          pack: '',
          brand: 'Coca Cola',
        ),
      ],
    ),
    OrderSummary(
      id: 'VH123455',
      status: 'Shipped',
      total: 790,
      createdAt: DateTime(2025, 5, 10),
      itemCount: 2,
      items: const [],
    ),
    OrderSummary(
      id: 'VH123454',
      status: 'Pending',
      total: 210,
      createdAt: DateTime(2025, 5, 8),
      itemCount: 4,
      items: const [],
    ),
  ];
}

List<(String, String, bool)> _stepsForStatus(String status) {
  final normalized = status.toLowerCase();
  final current = normalized.contains('deliver')
      ? 5
      : normalized.contains('out')
          ? 4
          : normalized.contains('ship')
              ? 3
              : normalized.contains('pack')
                  ? 2
                  : normalized.contains('confirm')
                      ? 1
                      : 0;
  const titles = [
    'Order Placed',
    'Order Confirmed',
    'Packed',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];
  return [
    for (var i = 0; i < titles.length; i++)
      (
        titles[i],
        i == 0 ? 'Order received' : 'Updates as it moves',
        i <= current
      ),
  ];
}

List<(String, String, bool)> _stepsForOrder(OrderSummary order) {
  if (order.statusHistory.isEmpty) return _stepsForStatus(order.status);
  const titles = {
    'placed': 'Order Placed',
    'confirmed': 'Order Confirmed',
    'packed': 'Packed',
    'shipped': 'Shipped',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
  };
  final historyByStatus = {
    for (final event in order.statusHistory) event.status.toLowerCase(): event,
  };
  return [
    for (final status in const [
      'placed',
      'confirmed',
      'packed',
      'shipped',
      'out_for_delivery',
      'delivered',
    ])
      (
        titles[status]!,
        historyByStatus[status]?.changedAt == null
            ? 'Awaiting update'
            : _dateTime(historyByStatus[status]!.changedAt),
        historyByStatus.containsKey(status),
      ),
  ];
}

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(value.length - 8).toUpperCase();
}

Future<void> _openOrderInvoice(
  BuildContext context,
  OrderSummary order,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _CustomerInvoiceScreen(order: order),
    ),
  );
}

String _buildInvoiceShareText(OrderSummary order) {
  final buffer = StringBuffer()
    ..writeln('VyparHub Invoice INV-${_shortId(order.id)}')
    ..writeln('Order placed: ${_dateTime(order.createdAt)}')
    ..writeln('Status: ${order.status.toUpperCase().replaceAll('_', ' ')}')
    ..writeln()
    ..writeln('Items:');

  for (final item in order.items) {
    buffer.writeln(
      '- ${item.name} x${item.quantity}: ${money(item.buyPrice * item.quantity)}',
    );
  }

  buffer
    ..writeln()
    ..writeln('Grand total: ${money(order.total)}')
    ..writeln(
      'Payment: ${order.payment?.mode ?? 'COD'} (${order.payment?.status ?? order.status})',
    )
    ..writeln()
    ..writeln('Thank you for shopping with VyparHub.');

  return buffer.toString();
}

String _filterLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'all' || normalized == 'all orders') return 'All Orders';
  if (normalized == 'pending') return 'Pending';
  if (normalized == 'shipped') return 'Shipped';
  if (normalized == 'delivered') return 'Delivered';
  if (normalized == 'cancelled' || normalized == 'canceled') return 'Cancelled';
  if (value.isEmpty) return 'All Orders';
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _longDate(DateTime? value) {
  if (value == null) return 'Recent';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Recent';
  final hour = value.hour == 0 ? 10 : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : hour;
  return '${_longDate(value)}, $displayHour:$minute $suffix';
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE8EAF2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .04),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
