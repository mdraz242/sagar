part of 'orders_screen.dart';

class EditOrderScreen extends ConsumerStatefulWidget {
  const EditOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends ConsumerState<EditOrderScreen> {
  final quantities = <String, int>{};
  final search = TextEditingController();
  bool initialized = false;
  bool saving = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    final products =
        ref.watch(catalogSnapshotProvider).valueOrNull?.products ?? const [];

    return _OrderSubShell(
      title: 'Edit Order',
      child: order.when(
        loading: () => const VyparSkeletonList(itemCount: 4),
        error: (error, _) => _RetryState(
          title: 'Could not load order',
          message: apiErrorMessage(error),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          if (!initialized) {
            for (final item in order.items) {
              quantities[item.productId] = item.quantity;
            }
            initialized = true;
          }

          final query = search.text.trim().toLowerCase();
          final visibleProducts = products.where((product) {
            if (query.isEmpty) return quantities.containsKey(product.id);
            return product.name.toLowerCase().contains(query) ||
                product.brand.toLowerCase().contains(query);
          }).toList();
          final editable = _canCustomerModify(order);
          final selectedTotal = quantities.entries.fold<num>(0, (sum, entry) {
            final product = products.where((item) => item.id == entry.key);
            if (product.isEmpty) {
              final snapshot =
                  order.items.where((item) => item.productId == entry.key);
              return sum +
                  (snapshot.isEmpty
                      ? 0
                      : snapshot.first.buyPrice * entry.value);
            }
            return sum + product.first.buyPrice * entry.value;
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              VyparCard(
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
                    const SizedBox(height: 6),
                    Text(
                      editable
                          ? 'Adjust quantities or add products before this order is confirmed.'
                          : 'This order can no longer be edited because it is older than 2 days or already confirmed.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: search,
                enabled: editable,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search products to add',
                ),
              ),
              const SizedBox(height: 14),
              if (!editable)
                VyparEmptyState(
                  icon: Icons.lock_clock_outlined,
                  title: 'Editing window closed',
                  subtitle:
                      'Placed orders can be changed only within 2 days and before confirmation.',
                  actionLabel: 'Back to Order',
                  onAction: () => context.go('/orders/${order.id}'),
                )
              else ...[
                for (final item in order.items)
                  if (quantities.containsKey(item.productId))
                    _EditableOrderItem(
                      imageUrl: item.imageUrl,
                      name: item.name,
                      subtitle: [item.size, item.pack]
                          .where((part) => part.isNotEmpty)
                          .join(' - '),
                      price: item.buyPrice,
                      quantity: quantities[item.productId] ?? item.quantity,
                      onChanged: (value) {
                        setState(() {
                          if (value <= 0) {
                            quantities.remove(item.productId);
                          } else {
                            quantities[item.productId] = value;
                          }
                        });
                      },
                    ),
                if (visibleProducts.isNotEmpty && search.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Text(
                      'Add products',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                if (search.text.trim().isNotEmpty)
                  for (final product in visibleProducts.take(12))
                    if (!quantities.containsKey(product.id))
                      _EditableOrderItem(
                        imageUrl: product.image,
                        name: product.name,
                        subtitle: product.size,
                        price: product.buyPrice,
                        quantity: 0,
                        addMode: true,
                        onChanged: (value) {
                          setState(() => quantities[product.id] = value);
                        },
                      ),
                const SizedBox(height: 14),
                VyparCard(
                  child: Column(
                    children: [
                      _SummaryRow('Updated Total', money(selectedTotal),
                          bold: true),
                      const SizedBox(height: 12),
                      VyparButton.primary(
                        label: saving ? 'Saving...' : 'Save Changes',
                        icon:
                            saving ? Icons.hourglass_top : Icons.save_outlined,
                        onPressed: saving || quantities.isEmpty
                            ? null
                            : () async {
                                setState(() => saving = true);
                                try {
                                  await ref.read(orderApiProvider).updateItems(
                                        orderId: widget.orderId,
                                        items: quantities.entries
                                            .map((entry) => {
                                                  'productId': entry.key,
                                                  'quantity': entry.value,
                                                })
                                            .toList(),
                                      );
                                  ref.invalidate(ordersProvider);
                                  ref.invalidate(
                                      orderDetailProvider(widget.orderId));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Order updated.'),
                                    ),
                                  );
                                  context.go('/orders/${widget.orderId}');
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(apiErrorMessage(error)),
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => saving = false);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EditableOrderItem extends StatelessWidget {
  const _EditableOrderItem({
    required this.imageUrl,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.onChanged,
    this.addMode = false,
  });

  final String imageUrl;
  final String name;
  final String subtitle;
  final num price;
  final int quantity;
  final ValueChanged<int> onChanged;
  final bool addMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 54,
            child: CatalogImage(imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Product' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                Text(
                  money(price),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (addMode)
            OutlinedButton(
              onPressed: () => onChanged(1),
              child: const Text('ADD'),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.success),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onChanged(quantity - 1),
                    icon: const Icon(Icons.remove),
                    color: AppColors.success,
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onChanged(quantity + 1),
                    icon: const Icon(Icons.add),
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
