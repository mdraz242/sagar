import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../application/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(catalogSnapshotProvider);
    if (catalog.isLoading) {
      return const AppShell(child: VyparSkeletonList(itemCount: 4));
    }
    if (catalog.hasError) {
      return AppShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 112),
          child: VyparEmptyState(
            icon: Icons.wifi_off_outlined,
            title: 'Could not load cart products',
            subtitle: catalog.error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(catalogSnapshotProvider),
          ),
        ),
      );
    }
    final products = catalog.valueOrNull?.products ?? const [];
    final lines = cartLines(cart, products);
    final unavailable = unavailableCartLines(cart, products);
    final hasUnavailable = unavailable.isNotEmpty;
    final cartCount = lines.length + unavailable.length;
    final subtotal = cartBuy(cart, products);
    final delivery =
        subtotal == 0 || subtotal >= AppConfig.freeDeliveryThreshold ? 0 : 20;
    final total = subtotal + delivery;
    final remaining =
        (AppConfig.freeDeliveryThreshold - subtotal).clamp(0, 999999);
    final progress =
        (subtotal / AppConfig.freeDeliveryThreshold).clamp(0, 1).toDouble();

    ref.listen<String?>(cartErrorProvider, (_, next) {
      if (next != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return AppShell(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              cartCount == 0 ? 108 : 204,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Cart ($cartCount)',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: cartCount == 0
                        ? null
                        : () => ref.read(cartProvider.notifier).clear(),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (cartCount == 0)
                Container(
                  padding: const EdgeInsets.all(34),
                  decoration: _cartCard(),
                  child: Column(
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: AppColors.orange, size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => context.go('/category'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                        ),
                        child: const Text('Start Quick Buy'),
                      ),
                    ],
                  ),
                )
              else ...[
                if (lines.isNotEmpty) ...[
                  const _SectionTitle('Available Items'),
                  const SizedBox(height: 8),
                  for (final line in lines)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: _cartCard(),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 82,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CatalogImage(line.product.image),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  line.subtitle,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  money(line.buyPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.blue),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 32,
                                        ),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .add(line.cartKey, -1),
                                        color: AppColors.blue,
                                        splashColor: AppColors.orange
                                            .withValues(alpha: .14),
                                        highlightColor: AppColors.orange
                                            .withValues(alpha: .08),
                                        icon:
                                            const Icon(Icons.remove, size: 16),
                                      ),
                                      Text(
                                        '${line.qty}',
                                        style: const TextStyle(
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 32,
                                        ),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .add(line.cartKey),
                                        color: AppColors.blue,
                                        splashColor: AppColors.orange
                                            .withValues(alpha: .14),
                                        highlightColor: AppColors.orange
                                            .withValues(alpha: .08),
                                        icon: const Icon(Icons.add, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .remove(line.cartKey),
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                              ),
                              Text(
                                money(line.buyPrice * line.qty),
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
                if (hasUnavailable) ...[
                  const SizedBox(height: 8),
                  _SectionTitle('Unavailable Items (${unavailable.length})'),
                  const SizedBox(height: 8),
                  for (final item in unavailable)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: _cartCard(
                        color: const Color(0xFFF4F5F7),
                        borderColor: const Color(0xFFE0E2E8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 82,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.muted,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  item.reason,
                                  style: const TextStyle(
                                    color: AppColors.primaryAlt,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.qty}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .remove(item.cartKey),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove'),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryAlt),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.primaryAlt,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Some items in your cart are no longer available.',
                                style: TextStyle(
                                  color: AppColors.primaryAlt,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .removeAll(
                                    unavailable.map((item) => item.cartKey)),
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text('Remove All Unavailable Items'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remaining == 0
                            ? 'Free delivery unlocked!'
                            : 'You are ${money(remaining)} away from FREE delivery',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          color: AppColors.orange,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Rs999',
                          style: TextStyle(color: AppColors.muted, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _cartCard(),
                  child: Column(
                    children: [
                      _SummaryRow('Item Total (${lines.length} items)',
                          money(subtotal)),
                      _SummaryRow('Delivery Charges',
                          delivery == 0 ? 'FREE' : money(delivery)),
                      const Divider(height: 24),
                      _SummaryRow('Grand Total', money(total), bold: true),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (cartCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            money(total),
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: hasUnavailable
                          ? () => ref.read(cartProvider.notifier).removeAll(
                              unavailable.map((item) => item.cartKey))
                          : lines.isEmpty
                              ? null
                              : () => context.go('/checkout'),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasUnavailable
                            ? AppColors.primaryAlt
                            : AppColors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        hasUnavailable
                            ? 'Remove unavailable items'
                            : 'Proceed to Checkout',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.blue,
        fontWeight: FontWeight.w900,
        fontSize: 14,
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
              color: AppColors.blue,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cartCard({
  Color color = Colors.white,
  Color borderColor = const Color(0xFFE8EAF2),
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .045),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
