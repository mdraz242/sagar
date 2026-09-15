part of 'orders_screen.dart';

class OrderActionScreen extends ConsumerStatefulWidget {
  const OrderActionScreen({
    super.key,
    required this.orderId,
    required this.action,
  });

  final String orderId;
  final String action;

  @override
  ConsumerState<OrderActionScreen> createState() => _OrderActionScreenState();
}

class _OrderActionScreenState extends ConsumerState<OrderActionScreen> {
  int rating = 5;
  bool submitting = false;
  int step = 0;
  late String requestType;
  String refundMethod = 'wallet';
  String selectedReason = '';
  final selectedQuantities = <String, int>{};
  final reason = TextEditingController();
  final notes = TextEditingController();

  static const returnReasons = [
    'Damaged product',
    'Wrong item delivered',
    'Expired stock',
    'Pack mismatch',
    'Quality issue',
  ];

  static const exchangeReasons = [
    'Wrong pack size',
    'Damaged product',
    'Quantity mismatch',
    'Need replacement item',
  ];

  @override
  void initState() {
    super.initState();
    requestType = widget.action == 'exchange' ? 'exchange' : 'return';
  }

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReview = widget.action == 'review';
    final isReturn = requestType == 'return';
    final title = isReview
        ? 'Review Order'
        : isReturn
            ? 'Return Order'
            : 'Exchange Order';
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return _OrderSubShell(
      title: title,
      child: order.when(
        loading: () => const VyparSkeletonList(itemCount: 4),
        error: (error, _) {
          if (isReview) return _buildReview(context);
          return _RetryState(
            title: 'Could not load order',
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
          );
        },
        data: (order) =>
            isReview ? _buildReview(context) : _buildFlow(context, order),
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        VyparCard(
          child: Column(
            children: [
              Text(
                'Order #${_shortId(widget.orderId)}',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'How was your order?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => rating = i),
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: reason,
          minLines: 4,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Write your review',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        VyparButton.primary(
          label: submitting ? 'Submitting...' : 'Submit Review',
          icon: submitting ? Icons.hourglass_top : Icons.star_outline,
          onPressed: submitting
              ? null
              : () async {
                  setState(() => submitting = true);
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted.')),
                  );
                  context.go('/orders/${widget.orderId}');
                  if (mounted) setState(() => submitting = false);
                },
        ),
      ],
    );
  }

  Widget _buildFlow(BuildContext context, OrderSummary order) {
    if (requestType == 'exchange' && !_canRequestExchange(order)) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          VyparEmptyState(
            icon: Icons.swap_horiz_outlined,
            title: 'Exchange window closed',
            subtitle:
                'Exchange is available only within 3 days after delivery. You can still request a return if it is within the return window.',
            actionLabel: _canRequestReturn(order) ? 'Request Return' : 'Back',
            onAction: () => _canRequestReturn(order)
                ? setState(() {
                    requestType = 'return';
                    step = 0;
                  })
                : goBackOr(context, '/orders/${order.id}'),
          ),
        ],
      );
    }
    if (selectedQuantities.isEmpty && order.items.isNotEmpty) {
      selectedQuantities[order.items.first.productId] = 1;
    }
    final selectedCount =
        selectedQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
      children: [
        _ReturnStepHeader(
          currentStep: step,
          requestType: requestType,
        ),
        const SizedBox(height: 14),
        if (step == 0) _helpStep(),
        if (step == 1) _selectItemsStep(order),
        if (step == 2) _methodStep(),
        const SizedBox(height: 18),
        VyparButton.primary(
          label: step < 2
              ? selectedCount > 0 && step == 1
                  ? 'Continue with $selectedCount item${selectedCount == 1 ? '' : 's'}'
                  : 'Continue'
              : submitting
                  ? 'Submitting...'
                  : requestType == 'return'
                      ? 'Submit Return Request'
                      : 'Submit Exchange Request',
          icon: submitting ? Icons.hourglass_top : Icons.arrow_forward,
          onPressed: submitting || !_canContinue(selectedCount)
              ? null
              : () {
                  if (step < 2) {
                    setState(() => step += 1);
                    return;
                  }
                  _submitRequest(context, order);
                },
        ),
      ],
    );
  }

  Widget _helpStep() {
    final reasons = requestType == 'return' ? returnReasons : exchangeReasons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VyparCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How can we help?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceTile(
                      selected: requestType == 'return',
                      icon: Icons.assignment_return_outlined,
                      title: 'Return',
                      subtitle: 'Refund for selected items',
                      onTap: () => setState(() {
                        requestType = 'return';
                        selectedReason = '';
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceTile(
                      selected: requestType == 'exchange',
                      icon: Icons.swap_horiz_outlined,
                      title: 'Exchange',
                      subtitle: 'Replacement request',
                      onTap: () => setState(() {
                        requestType = 'exchange';
                        selectedReason = '';
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        VyparCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a reason',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final item in reasons)
                _SelectableOptionRow(
                  title: item,
                  selected: selectedReason == item,
                  onTap: () => setState(() => selectedReason = item),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectItemsStep(OrderSummary order) {
    return VyparCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Items',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the exact products and quantity for this request.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          for (final item in order.items)
            _SelectableReturnItem(
              item: item,
              quantity: selectedQuantities[item.productId] ?? 0,
              onChanged: (qty) {
                setState(() {
                  if (qty <= 0) {
                    selectedQuantities.remove(item.productId);
                  } else {
                    selectedQuantities[item.productId] =
                        qty.clamp(1, item.quantity).toInt();
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _methodStep() {
    final isReturn = requestType == 'return';
    return Column(
      children: [
        VyparCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReturn ? 'Refund Method' : 'Exchange Method',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (isReturn)
                for (final method in const [
                  (
                    'original_payment',
                    'Original Payment Method',
                    'Back to source account'
                  ),
                  (
                    'wallet',
                    'VyparHub Wallet',
                    'Recommended - fastest approval'
                  ),
                  (
                    'upi',
                    'UPI-Bank Transfer',
                    'Manual transfer after approval'
                  ),
                  ('store_credit', 'Store Credit', 'Use on next order'),
                ])
                  _SelectableOptionRow(
                    title: method.$2,
                    subtitle: method.$3,
                    selected: refundMethod == method.$1,
                    onTap: () => setState(() => refundMethod = method.$1),
                  )
              else
                const Text(
                  'Our support team will confirm replacement stock and schedule pickup or delivery after admin approval.',
                  style: TextStyle(color: AppColors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: notes,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add details for support (optional)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  bool _canContinue(int selectedCount) {
    if (step == 0) return selectedReason.isNotEmpty;
    if (step == 1) return selectedCount > 0;
    return true;
  }

  Future<void> _submitRequest(BuildContext context, OrderSummary order) async {
    setState(() => submitting = true);
    try {
      final selectedItems = order.items
          .where((item) => selectedQuantities.containsKey(item.productId))
          .map((item) => {
                'productId': item.productId,
                'quantity': selectedQuantities[item.productId] ?? 1,
              })
          .toList();
      if (!AppConfig.useMockData) {
        await ref.read(orderApiProvider).requestRefund(
              orderId: widget.orderId,
              reason: selectedReason,
              refundMethod:
                  requestType == 'exchange' ? 'store_credit' : refundMethod,
              requestType: requestType,
              items: selectedItems,
              customerNotes: notes.text.trim(),
            );
        ref.invalidate(ordersProvider);
        ref.invalidate(orderDetailProvider(widget.orderId));
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requestType == 'return'
                ? 'Return request submitted.'
                : 'Exchange request submitted.',
          ),
        ),
      );
      context.go('/orders/${widget.orderId}');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

class _ReturnRequestBanner extends StatelessWidget {
  const _ReturnRequestBanner({required this.request});

  final ReturnRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final type = request.requestType == 'exchange' ? 'Exchange' : 'Return';
    final status = request.status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type request: $status',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  request.rejectionReason?.isNotEmpty == true
                      ? request.rejectionReason!
                      : request.reason,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnStepHeader extends StatelessWidget {
  const _ReturnStepHeader({
    required this.currentStep,
    required this.requestType,
  });

  final int currentStep;
  final String requestType;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Help',
      'Items',
      requestType == 'return' ? 'Refund' : 'Exchange',
    ];
    return VyparCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requestType == 'return' ? 'Return Request' : 'Exchange Request',
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i <= currentStep
                      ? AppColors.orange
                      : const Color(0xFFE8EAF2),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    color: i <= currentStep ? AppColors.blue : AppColors.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (i != labels.length - 1)
                  const Expanded(
                    child: Divider(indent: 8, endIndent: 8),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4EA) : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.orange : const Color(0xFFE8EAF2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.orange : AppColors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableOptionRow extends StatelessWidget {
  const _SelectableOptionRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.orange : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle?.isNotEmpty == true)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableReturnItem extends StatelessWidget {
  const _SelectableReturnItem({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  final OrderItemSnapshot item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF9F4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.orange : const Color(0xFFE8EAF2),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            activeColor: AppColors.orange,
            onChanged: (value) => onChanged(value == true ? 1 : 0),
          ),
          SizedBox(
            width: 46,
            height: 50,
            child: CatalogImage(item.imageUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Product' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  [item.size, item.pack]
                      .where((part) => part.isNotEmpty)
                      .join(' - '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                Text(
                  'Ordered qty: ${item.quantity}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.orange),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onChanged(quantity - 1),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.remove, size: 16),
                    ),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  InkWell(
                    onTap: () => onChanged(quantity + 1),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 112),
      children: [
        VyparEmptyState(
          icon: Icons.wifi_off_outlined,
          title: title,
          subtitle: message,
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      ],
    );
  }
}
