part of 'orders_screen.dart';

class _CustomerInvoiceScreen extends StatelessWidget {
  const _CustomerInvoiceScreen({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final address = order.address;
    final subtotal = order.items.fold<num>(
      0,
      (total, item) => total + (item.buyPrice * item.quantity),
    );
    final effectiveSubtotal = subtotal > 0 ? subtotal : order.total;
    final deliveryCharge = (order.total - effectiveSubtotal).clamp(0, 999999);
    final status = order.status.toUpperCase().replaceAll('_', ' ');
    final isCancelled = order.status.toLowerCase() == 'cancelled';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Invoice #${_shortId(order.id)}'),
        actions: [
          IconButton(
            tooltip: 'Share invoice',
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: _buildInvoiceShareText(order)),
            ),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.blue,
                              ),
                              children: [
                                TextSpan(text: 'Vypar'),
                                TextSpan(
                                  text: 'Hub',
                                  style: TextStyle(color: AppColors.orange),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Makers seh Market tak',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? AppColors.orange.withValues(alpha: 0.12)
                            : AppColors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color:
                              isCancelled ? AppColors.orange : AppColors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _InvoiceMetaRow(
                  label: 'Invoice No.',
                  value: 'INV-${_shortId(order.id)}',
                ),
                _InvoiceMetaRow(
                  label: 'Invoice Date',
                  value: _longDate(DateTime.now()),
                ),
                _InvoiceMetaRow(
                  label: 'Order Placed',
                  value: _dateTime(order.createdAt),
                ),
                _InvoiceMetaRow(
                  label: 'Payment',
                  value:
                      '${order.payment?.mode ?? 'COD'} - ${order.payment?.status ?? order.status}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill To',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  address?.name.isNotEmpty == true ? address!.name : 'Customer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(address?.phone ?? ''),
                const SizedBox(height: 6),
                Text(
                  address?.display ?? 'Delivery address not available',
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.map(_InvoiceLineItem.new),
                const Divider(height: 28),
                _SummaryRow('Subtotal', money(effectiveSubtotal)),
                _SummaryRow(
                  'Delivery Charge',
                  deliveryCharge == 0 ? 'FREE' : money(deliveryCharge),
                ),
                const Divider(height: 28),
                _SummaryRow('Grand Total', money(order.total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(18),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you for shopping with VyparHub.',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'For support, contact support@vyparhub.com.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetaRow extends StatelessWidget {
  const _InvoiceMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLineItem extends StatelessWidget {
  const _InvoiceLineItem(this.item);

  final OrderItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    final description = [
      item.size,
      item.pack,
    ].where((value) => value.isNotEmpty).join(' - ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} x ${money(item.buyPrice)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            money(item.buyPrice * item.quantity),
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotDetailItem extends StatelessWidget {
  const _SnapshotDetailItem({required this.item});

  final OrderItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 44,
            child: CatalogImage(item.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Order item' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  [item.size, item.pack].where((e) => e.isNotEmpty).join(' - '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(item.buyPrice * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              Text('Qty: ${item.quantity}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
