import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/api_catalog_repository.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../auth/application/auth_provider.dart';
import '../../cart/application/cart_provider.dart';

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  if (AppConfig.useMockData) return Future.value(const []);
  return ref.watch(addressApiProvider).list();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0;
  String _payment = 'cod';
  String _coupon = '';
  String? _selectedAddressId;
  String? _error;
  bool _placing = false;
  String? _checkoutAttemptKey;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(catalogSnapshotProvider).valueOrNull;
    final products = catalog?.products ?? const [];
    final lines = cartLines(cart, products);
    final unavailable = unavailableCartLines(cart, products);
    final itemTotal = cartBuy(cart, products);
    final discount = _coupon.trim().toUpperCase() == 'VYPAR50' ? 50 : 0;
    final delivery =
        itemTotal == 0 || itemTotal >= AppConfig.freeDeliveryThreshold ? 0 : 20;
    final grandTotal = (itemTotal + delivery - discount).clamp(0, 999999);

    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CheckoutHeader(
              step: _step,
              onBack: () {
                if (_step == 0) {
                  context.go('/cart');
                } else {
                  setState(() => _step--);
                }
              },
            ),
            _StepProgress(step: _step),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.primaryAlt,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                children: [
                  if (_step == 0) _addressStep(),
                  if (_step == 1) _paymentStep(),
                  if (_step == 2)
                    if (unavailable.isNotEmpty) ...[
                      VyparCard(
                        color: const Color(0xFFFFF5F2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cart needs attention',
                              style: TextStyle(
                                color: AppColors.primaryAlt,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            for (final item in unavailable)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${item.title}: ${item.reason}',
                                  style: const TextStyle(
                                    color: AppColors.primaryAlt,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            VyparButton.ghost(
                              label: 'Review Cart',
                              icon: Icons.shopping_cart_checkout,
                              onPressed: () => context.go('/cart'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (_step == 2)
                    _reviewStep(
                      lines: lines,
                      itemTotal: itemTotal,
                      delivery: delivery,
                      discount: discount,
                      grandTotal: grandTotal,
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.paddingOf(context).bottom + 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: VyparButton.primary(
                  label: _step == 2
                      ? _placing
                          ? 'Placing Order...'
                          : 'Place Order'
                      : 'Continue',
                  icon: _step == 2
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                  onPressed: _placing || lines.isEmpty || unavailable.isNotEmpty
                      ? null
                      : () => _continueOrPlace(lines, grandTotal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressStep() {
    final addresses = ref.watch(addressesProvider);
    final user = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        addresses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _AddressOption(
            selected: _selectedAddressId == 'profile',
            title: user?.name ?? 'VyparHub Retailer',
            subtitle: [
              user?.address ?? 'Main Road',
              user?.area ?? 'your area',
              user?.pincode ?? '854340',
            ].join(', '),
            onTap: () => setState(() => _selectedAddressId = 'profile'),
          ),
          data: (items) {
            final shown = items.isEmpty
                ? [
                    Address(
                      id: 'profile',
                      name: user?.name ?? 'VyparHub Retailer',
                      phone: user?.phone ?? '',
                      line1: user?.address ?? 'Main Road',
                      area: user?.area ?? 'your area',
                      city: user?.area ?? '',
                      state: 'Bihar',
                      pincode: user?.pincode.isNotEmpty == true
                          ? user!.pincode
                          : '854340',
                      isDefault: true,
                    ),
                  ]
                : items;
            _selectedAddressId ??= shown.first.id;
            return Column(
              children: [
                for (final address in shown)
                  _AddressOption(
                    selected: _selectedAddressId == address.id,
                    title:
                        address.name.isEmpty ? 'Saved Address' : address.name,
                    subtitle: address.display,
                    onTap: () =>
                        setState(() => _selectedAddressId = address.id),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        VyparButton.ghost(
          label: 'Add / Manage Address',
          icon: Icons.add_location_alt_outlined,
          onPressed: () => context.go('/profile/addresses'),
        ),
      ],
    );
  }

  Widget _paymentStep() {
    const methods = [
      (
        'cod',
        Icons.payments_outlined,
        'Cash on Delivery',
        'Pay when order is delivered'
      ),
      (
        'upi',
        Icons.account_balance_wallet_outlined,
        'UPI',
        'Prepared for Razorpay activation'
      ),
      (
        'card',
        Icons.credit_card,
        'Debit / Credit Card',
        'Prepared for Razorpay activation'
      ),
      (
        'wallet',
        Icons.wallet_outlined,
        'Wallet',
        'Use available Vypar wallet balance'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (final method in methods)
          _PaymentOption(
            selected: _payment == method.$1,
            icon: method.$2,
            title: method.$3,
            subtitle: method.$4,
            onTap: () {
              if (method.$1 == 'cod') {
                setState(() => _payment = method.$1);
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${method.$3} is coming soon. Cash on Delivery is active.'),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _reviewStep({
    required List<CartLine> lines,
    required num itemTotal,
    required num delivery,
    required num discount,
    required num grandTotal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        VyparCard(
          child: Column(
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 48,
                        child: CatalogImage(line.product.image),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${line.subtitle} - Qty ${line.qty}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(line.buyPrice * line.qty),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _coupon = value),
          decoration: InputDecoration(
            hintText: 'Apply coupon or offer code',
            prefixIcon: const Icon(Icons.local_offer_outlined),
            suffixIcon: TextButton(
              onPressed: () => setState(() => _coupon = 'VYPAR50'),
              child: const Text('Apply'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        VyparCard(
          child: Column(
            children: [
              _SummaryRow('Item Total', money(itemTotal)),
              _SummaryRow(
                  'Delivery Charges', delivery == 0 ? 'FREE' : money(delivery)),
              _SummaryRow('Coupon Discount',
                  discount == 0 ? '-' : '-${money(discount)}'),
              const Divider(height: 24),
              _SummaryRow('To Pay', money(grandTotal), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _continueOrPlace(List<CartLine> lines, num total) async {
    setState(() => _error = null);
    if (_step < 2) {
      if (_step == 0 && _selectedAddressId == null) {
        setState(() => _error = 'Select a delivery address.');
        return;
      }
      setState(() => _step++);
      return;
    }

    setState(() => _placing = true);
    var orderId =
        'VH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    try {
      if (!AppConfig.useMockData && _selectedAddressId != null) {
        var resolvedAddressId = _selectedAddressId;
        if (resolvedAddressId == 'profile') {
          final user = ref.read(authProvider);
          final saved = await ref.read(addressApiProvider).create({
            'name': user?.name ?? 'VyparHub Retailer',
            'phone': user?.phone ?? '',
            'line1': user?.address ?? 'Main Road',
            'area': user?.area ?? 'your area',
            'city': user?.area ?? '',
            'state': 'Bihar',
            'pincode':
                user?.pincode.isNotEmpty == true ? user!.pincode : '854340',
            'isDefault': true,
          });
          resolvedAddressId = saved.id;
        }
        _checkoutAttemptKey ??= _newCheckoutAttemptKey(lines);
        final order = await ref.read(orderApiProvider).create(
          addressId: resolvedAddressId,
          paymentMode: _payment,
          notes: 'Checkout payment: $_payment; coupon: $_coupon',
          idempotencyKey: _checkoutAttemptKey,
          items: [
            for (final line in lines)
              {
                'productId': line.product.id,
                'quantity': line.qty,
                if (line.variant?.id?.isNotEmpty == true)
                  'variantKey': line.variant!.id,
                if (line.variant != null &&
                    line.variant?.id?.isNotEmpty != true)
                  'variantKey': line.variant!.keyPart,
              },
          ],
        );
        orderId = order.id;
      }
      ref.read(cartProvider.notifier).clear();
      _checkoutAttemptKey = null;
      if (mounted) {
        context.go(
          '/checkout/confirmation?id=${Uri.encodeComponent(orderId)}&total=$total',
        );
      }
    } catch (error) {
      setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  String _newCheckoutAttemptKey(List<CartLine> lines) {
    final signature = lines
        .map((line) =>
            '${line.product.id}:${line.variant?.id ?? line.variant?.keyPart ?? 'default'}:${line.qty}')
        .join('|');
    final hash = signature.hashCode.toUnsigned(32);
    return 'checkout:${DateTime.now().microsecondsSinceEpoch}:$hash';
  }
}

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.total,
  });

  final String orderId;
  final String total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final query = DeliveryLocationQuery(
      area: user?.area ?? '',
      city: user?.area ?? '',
      pincode: user?.pincode ?? '',
    );
    final deliveryContext =
        ref.watch(deliveryContextProvider(query)).valueOrNull;
    final delivery = deliveryContext?.serviceable == true
        ? deliveryContext!.etaLabel
        : 'not currently serviceable';
    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 112),
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 104),
            const SizedBox(height: 20),
            const Text(
              'Order Placed!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${_shortId(orderId)} is confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            VyparCard(
              child: Column(
                children: [
                  _SummaryRow('Estimated Arrival', 'Within $delivery'),
                  _SummaryRow('Amount',
                      total.isEmpty ? '-' : money(num.tryParse(total) ?? 0)),
                  _SummaryRow('Status', 'Placed', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            VyparButton.primary(
              label: 'Track Order',
              icon: Icons.route_outlined,
              onPressed: () => context.go('/orders/$orderId/tracking'),
            ),
            const SizedBox(height: 10),
            VyparButton.ghost(
              label: 'Continue Shopping',
              icon: Icons.storefront_outlined,
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const titles = ['Checkout', 'Payment', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.blue),
          ),
          Expanded(
            child: Text(
              titles[step],
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Address', 'Payment', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  i <= step ? AppColors.primaryAlt : AppColors.border,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: i <= step ? Colors.white : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              labels[i],
              style: TextStyle(
                color: i <= step ? AppColors.blue : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (i != labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AddressOption extends StatelessWidget {
  const _AddressOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primaryAlt : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
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
    return VyparCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.primaryAlt : AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primaryAlt : AppColors.muted,
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(value.length - 8).toUpperCase();
}
