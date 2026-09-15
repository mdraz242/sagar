part of 'orders_screen.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return _OrderSubShell(
      title: 'Order Tracking',
      child: order.when(
        loading: () => const VyparSkeletonList(itemCount: 4),
        error: (error, _) {
          if (AppConfig.useMockData) {
            return _TrackingBody(order: _demoOrders().first);
          }
          return _RetryState(
            title: 'Could not load tracking',
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          );
        },
        data: (order) => _TrackingBody(order: order),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForOrder(order);
    final address = order.address;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${_shortId(order.id)}',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _dateTime(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(order.status),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final entry in steps.asMap().entries)
          _TrackingStep(
            entry.value.$1,
            entry.value.$2,
            done: entry.value.$3,
            last: entry.key == steps.length - 1,
          ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery address',
                        style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 5),
                    Text(address?.name.isNotEmpty == true
                        ? address!.name
                        : 'Saved Address'),
                    Text(address?.display ?? 'Address details unavailable'),
                  ],
                ),
              ),
              Container(
                width: 86,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9DEC6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.orange,
                  size: 42,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep(this.title, this.time,
      {this.done = false, this.last = false});

  final String title;
  final String time;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor:
                  done ? AppColors.success : const Color(0xFFE8EAF2),
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
            if (!last)
              Container(
                width: 2,
                height: 46,
                color: AppColors.success,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(time,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
