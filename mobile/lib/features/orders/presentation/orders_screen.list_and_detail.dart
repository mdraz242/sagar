part of 'orders_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final products =
        ref.watch(catalogSnapshotProvider).valueOrNull?.products ?? const [];
    final fallback = _demoOrders().firstWhere(
      (item) => item.id == orderId,
      orElse: () => _demoOrders().first,
    );

    return _OrderSubShell(
      title: '',
      child: order.when(
        loading: () => const VyparSkeletonList(itemCount: 4),
        error: (error, _) {
          if (AppConfig.useMockData) {
            return _OrderDetailBody(order: fallback, products: products);
          }
          return _RetryState(
            title: 'Could not load this order',
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          );
        },
        data: (order) => _OrderDetailBody(order: order, products: products),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({
    required this.orders,
    required this.products,
    this.action,
  });

  final List<OrderSummary> orders;
  final List<Product> products;
  final String? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(orderStatusFilterProvider);
    final filteredOrders = orders.where((order) {
      return filter == 'All Orders' ||
          order.status.toLowerCase() == filter.toLowerCase();
    }).toList();
    const filters = [
      'All Orders',
      'Pending',
      'Shipped',
      'Delivered',
      'Cancelled',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final item in filters)
                _StatusChip(
                  item,
                  selected: filter == item,
                  onTap: () {
                    ref.read(orderStatusFilterProvider.notifier).state = item;
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Text(
              'No orders found for this status.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final order in filteredOrders)
          _OrderCard(
            order: order,
            products: products,
            showActions: action == 'return' ||
                order.status.toLowerCase().contains('deliver'),
            onTap: () => context.push('/orders/${order.id}'),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.products,
    required this.onTap,
    this.showActions = false,
  });

  final OrderSummary order;
  final List<Product> products;
  final VoidCallback onTap;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final thumbs = order.items.take(3).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${_shortId(order.id)}',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _longDate(order.createdAt),
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (thumbs.isNotEmpty)
                  for (final item in thumbs)
                    Container(
                      width: 54,
                      height: 54,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CatalogImage(_imageFor(item)),
                    )
                else
                  const Text(
                    'Items will appear here',
                    style: TextStyle(color: AppColors.muted),
                  ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${order.itemCount == 0 ? order.items.length : order.itemCount} Items | ${money(order.total)}',
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/orders/${order.id}/return'),
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Return'),
                    ),
                  ),
                  if (_canRequestExchange(order)) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/orders/${order.id}/exchange'),
                        icon: const Icon(Icons.swap_horiz_outlined),
                        label: const Text('Exchange'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/orders/${order.id}/review'),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Review Order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _imageFor(OrderItemSnapshot item) {
    if (item.imageUrl.isNotEmpty) return item.imageUrl;
    for (final product in products) {
      if (product.id == item.productId) return product.image;
    }
    return '';
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order, required this.products});

  final OrderSummary order;
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = order.items;
    final itemTotal = order.total;
    final delivery = 0;
    final total = itemTotal + delivery;
    final address = order.address;
    final editable = _canCustomerModify(order);
    final cancellable = _canCustomerCancel(order);
    final returnable = _canRequestReturn(order);
    final latestRequest =
        order.returnRequests.isEmpty ? null : order.returnRequests.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${_shortId(order.id)}',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _dateTime(order.createdAt),
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            _StatusBadge(order.status),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/orders/${order.id}/tracking'),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Track Order'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openOrderInvoice(context, order),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Invoice'),
              ),
            ),
          ],
        ),
        if (editable || cancellable) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (editable)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/orders/${order.id}/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Order'),
                  ),
                ),
              if (editable && cancellable) const SizedBox(width: 10),
              if (cancellable)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _confirmCancelOrder(context, ref, order.id),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            editable
                ? 'Placed orders can be edited within 2 days. Orders can be cancelled before shipping.'
                : 'This order can still be cancelled before shipping.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (latestRequest != null) ...[
          const SizedBox(height: 12),
          _ReturnRequestBanner(request: latestRequest),
        ],
        if (returnable) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/orders/${order.id}/return'),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Return'),
                ),
              ),
              if (_canRequestExchange(order)) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/orders/${order.id}/exchange'),
                    icon: const Icon(Icons.swap_horiz_outlined),
                    label: const Text('Exchange'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/orders/${order.id}/review'),
              icon: const Icon(Icons.star_outline),
              label: const Text('Review Order'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _DetailSection(
          title: 'Delivery Address',
          action: TextButton(
            onPressed: () => context.go('/profile/addresses'),
            child: const Text('Change'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  address?.name.isNotEmpty == true
                      ? address!.name
                      : 'Saved Address',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              Text(address?.line1.isNotEmpty == true
                  ? address!.line1
                  : 'Address saved with order'),
              Text(address?.display ?? 'Delivery location unavailable'),
              Text(address?.phone ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Order Items',
          child: Column(
            children: [
              if (items.isNotEmpty)
                for (final item in items) _SnapshotDetailItem(item: item)
              else
                const Text(
                  'Order item details are not available for this order.',
                  style: TextStyle(color: AppColors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Order Summary',
          child: Column(
            children: [
              _SummaryRow('Item Total', money(itemTotal)),
              _SummaryRow(
                  'Delivery Charges', delivery == 0 ? 'FREE' : money(delivery)),
              const Divider(height: 24),
              _SummaryRow('Total Amount', money(total), bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmCancelOrder(
  BuildContext context,
  WidgetRef ref,
  String orderId,
) async {
  const reasons = [
    'Ordered by mistake',
    'Found cheaper elsewhere',
    'Delivery taking too long',
    'Changed my mind',
    'Other',
  ];
  final selectedReason = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Why cancel this order?'),
      children: [
        for (final reason in reasons)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, reason),
            child: Text(reason),
          ),
        const Divider(),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Order'),
        ),
      ],
    ),
  );

  if (selectedReason == null || !context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel order?'),
      content: Text(
        'Reason: $selectedReason\n\nIf payment was prepaid, a refund request will be sent to admin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Order'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
          child: const Text('Confirm Cancel'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    if (!AppConfig.useMockData) {
      await ref.read(orderApiProvider).cancel(orderId, reason: selectedReason);
      ref.invalidate(ordersProvider);
      ref.invalidate(orderDetailProvider(orderId));
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order cancelled.')),
    );
    context.go('/orders');
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(apiErrorMessage(error))),
    );
  }
}

bool _canCustomerModify(OrderSummary order) {
  if (order.status.toLowerCase() != 'placed') return false;
  final createdAt = order.createdAt;
  if (createdAt == null) return false;
  return DateTime.now().difference(createdAt).inHours <= 48;
}

bool _canCustomerCancel(OrderSummary order) {
  return ['placed', 'confirmed', 'packed'].contains(order.status.toLowerCase());
}

bool _canRequestReturn(OrderSummary order) {
  if (order.status.toLowerCase() != 'delivered') return false;
  final deliveredAt = _deliveredAt(order);
  if (deliveredAt == null) return true;
  return DateTime.now().difference(deliveredAt).inDays <= 7;
}

bool _canRequestExchange(OrderSummary order) {
  if (order.status.toLowerCase() != 'delivered') return false;
  final deliveredAt = _deliveredAt(order);
  if (deliveredAt == null) return false;
  return DateTime.now().difference(deliveredAt).inHours <= 72;
}

DateTime? _deliveredAt(OrderSummary order) {
  for (final event in order.statusHistory.reversed) {
    if (event.status.toLowerCase() == 'delivered') return event.changedAt;
  }
  return null;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.blue : AppColors.muted,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: bold ? AppColors.blue : AppColors.text,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, {this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : const Color(0xFFF4F7FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized.contains('deliver')
        ? AppColors.success
        : normalized.contains('ship')
            ? const Color(0xFFF59E0B)
            : AppColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'Pending' : status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
