part of 'profile_subpages.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: 'Payment Methods',
      action: TextButton(
        onPressed: () => context.go('/profile/payments/new'),
        child: const Text('+ Add New'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: const [
          _SectionLabel('Saved Payment Methods'),
          SizedBox(height: 10),
          _PaymentCard(Icons.account_balance_wallet, 'UPI', 'prakashkumar@upi',
              badge: 'Default'),
          _PaymentCard(
              Icons.credit_card, 'Visa ending in 4242', 'Expires 12/26'),
          _PaymentCard(
              Icons.credit_card, 'Mastercard ending in 5252', 'Expires 11/25'),
          _PaymentCard(
              Icons.credit_card, 'Rupay ending in 1234', 'Expires 09/27'),
          _PaymentCard(
              Icons.payments_outlined, 'Cash on Delivery', 'Pay on delivery'),
          SizedBox(height: 14),
          Center(
            child: Text(
              'Your payment details are safe and secure with us.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPaymentMethodScreen extends StatelessWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SubPageShell(
      title: 'Add Payment Method',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          const _SectionLabel('Choose Method'),
          const SizedBox(height: 10),
          _MethodTile(
            'UPI',
            'Coming soon with Razorpay',
            Icons.radio_button_unchecked,
            onTap: () => _comingSoon(context, 'UPI'),
          ),
          _MethodTile(
            'Debit / Credit Card',
            'Coming soon with Razorpay',
            Icons.radio_button_unchecked,
            onTap: () => _comingSoon(context, 'Card payments'),
          ),
          _MethodTile('Net Banking', 'All major banks supported',
              Icons.account_balance_outlined,
              onTap: () => _comingSoon(context, 'Net banking')),
          _MethodTile(
              'Wallet', 'Coming soon', Icons.account_balance_wallet_outlined,
              onTap: () => _comingSoon(context, 'Wallet payments')),
          const _MethodTile(
            'Cash on Delivery',
            'Active - pay when your order is delivered',
            Icons.radio_button_checked,
            selected: true,
          ),
          const SizedBox(height: 26),
          const Center(
            child: Text(
              '100% Secure Payments',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard(this.icon, this.title, this.subtitle, {this.badge});

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brightBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            )
          else
            const Icon(Icons.more_vert, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile(this.title, this.subtitle, this.icon,
      {this.selected = false, this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.brightBlue : AppColors.blue,
                size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _comingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('$label is coming soon. Cash on Delivery is active.')),
  );
}
