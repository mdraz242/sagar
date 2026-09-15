import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../cart/application/cart_provider.dart';
import '../../products/domain/product.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        Icons.check_circle,
        'Order Delivered',
        'Your order #VH123456 has been delivered.',
        '12 May, 11:45 AM',
        AppColors.success
      ),
      (
        Icons.local_offer,
        'Price Drop Alert',
        "Lay's Classic Salted is now 10% off.",
        '12 May, 09:30 AM',
        AppColors.orange
      ),
      (
        Icons.card_giftcard,
        'Offer Unlocked',
        'You have unlocked 5% cashback.',
        '11 May, 08:20 PM',
        AppColors.orange
      ),
      (
        Icons.new_releases,
        'New Arrival',
        'Maggi 2-Minute is now available.',
        '11 May, 06:10 PM',
        AppColors.brightBlue
      ),
      (
        Icons.local_shipping,
        'Order Shipped',
        'Your order #VH123455 is on the way.',
        '10 May, 02:30 PM',
        AppColors.brightBlue
      ),
      (
        Icons.alarm,
        'Reminder',
        'You have points expiring in 10 days.',
        '10 May, 11:00 AM',
        AppColors.orange
      ),
    ];
    return _SimpleSubShell(
      title: 'Notifications',
      action: IconButton(
        onPressed: () => context.go('/profile/settings'),
        icon: const Icon(Icons.settings_outlined),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          for (final row in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: row.$5.withValues(alpha: .12),
                    child: Icon(row.$1, color: row.$5, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.$2,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        Text(row.$3,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(row.$4,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked read.')),
              );
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int amount = 0;

  @override
  Widget build(BuildContext context) {
    return _SimpleSubShell(
      title: 'Wallet',
      action: TextButton(
        onPressed: () => _showWalletHistory(context),
        child: const Text('Transaction History'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: brandGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vypar Wallet Balance',
                          style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 8),
                      Text('Rs0.00',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Wallet top-up will activate with payments.',
                        ),
                      ),
                    );
                  },
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.orange),
                  child: const Text('Add Money'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Wallet Benefits'),
          const SizedBox(height: 10),
          const Row(
            children: [
              _BenefitTile(Icons.refresh, 'Easy Refunds'),
              SizedBox(width: 10),
              _BenefitTile(Icons.shield, 'Secure Payments'),
              SizedBox(width: 10),
              _BenefitTile(Icons.shopping_bag, 'Instant Checkout'),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Money to Wallet',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final value in [200, 500, 1000])
                      ChoiceChip(
                        label: Text('Rs$value'),
                        selected: amount == value,
                        onSelected: (_) => setState(() => amount = value),
                      ),
                    ChoiceChip(
                      label: const Text('Other'),
                      selected: ![0, 200, 500, 1000].contains(amount),
                      onSelected: (_) => setState(() => amount = 0),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'Rs ',
                    hintText: amount == 0 ? '0' : '$amount',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => amount = 0),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Wallet top-up will activate with payments.')),
                      );
                    },
                    style: _orangeButton(),
                    child: const Text('Add Money'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _WalletHistoryRow('Signup bonus pending', 'Today', 'Rs0'),
              _WalletHistoryRow(
                  'Refunds will appear here', 'No activity yet', 'Rs0'),
            ],
          ),
        ),
      ),
    );
  }
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref
            .watch(catalogSnapshotProvider)
            .valueOrNull
            ?.products
            .take(4)
            .toList() ??
        const <Product>[];
    return _SimpleSubShell(
      title: 'Wishlist',
      action: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wishlist edit mode opened.')),
          );
        },
        child: const Text('Edit'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          for (final product in products)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  SizedBox(
                      width: 48,
                      height: 58,
                      child: CatalogImage(product.image)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        Text(product.size,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11)),
                        Text(money(product.buyPrice),
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).add(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${product.name} moved to cart.')),
                      );
                    },
                    child: const Text('Move to Cart'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text('You may also like',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) => Container(
                width: 78,
                padding: const EdgeInsets.all(8),
                decoration: _cardDecoration(),
                child: CatalogImage(products[index].image),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openLegalPage(BuildContext context, String page) async {
    final uri = Uri.parse('${AppConfig.publicBaseUrl}/legal/$page');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return _SimpleSubShell(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          const _SectionLabel('Account'),
          const SizedBox(height: 8),
          _SettingsRow(Icons.person_outline, 'Profile Information',
              () => context.go('/profile')),
          _SettingsRow(Icons.lock_outline, 'Change Password', () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      const TextField(
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: 'Current password'),
                      ),
                      const SizedBox(height: 10),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'New password'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: _orangeButton(),
                        child: const Text('Update Password'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          _SettingsRow(Icons.location_on_outlined, 'Manage Addresses',
              () => context.go('/profile/addresses')),
          _SettingsRow(Icons.credit_card_outlined, 'Payment Methods',
              () => context.go('/profile/payments')),
          const SizedBox(height: 18),
          const _SectionLabel('Preferences'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('App Language',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                SegmentedButton<Lang>(
                  segments: const [
                    ButtonSegment(value: Lang.en, label: Text('English')),
                    ButtonSegment(value: Lang.hi, label: Text('हिंदी')),
                  ],
                  selected: {lang},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) {
                    if (value.first != lang) {
                      ref.read(langProvider.notifier).toggle();
                    }
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.surfaceCream,
                    selectedForegroundColor: AppColors.orange,
                    foregroundColor: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SettingsRow(
              Icons.language, 'Language', () => context.go('/profile/language'),
              trailing: lang == Lang.en ? 'English' : 'हिंदी'),
          _SettingsRow(
            Icons.currency_rupee,
            'Currency',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('VyparHub currently supports INR only.'),
                ),
              );
            },
            trailing: 'INR (Rs)',
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.w800)),
            secondary:
                const Icon(Icons.notifications_none, color: AppColors.blue),
            activeThumbColor: AppColors.brightBlue,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w800)),
            secondary:
                const Icon(Icons.dark_mode_outlined, color: AppColors.blue),
            activeThumbColor: AppColors.brightBlue,
            tileColor: Colors.white,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Others'),
          const SizedBox(height: 8),
          _SettingsRow(Icons.info_outline, 'About VyparHub',
              () => context.go('/profile/about')),
          _SettingsRow(Icons.privacy_tip_outlined, 'Privacy Policy',
              () => _openLegalPage(context, 'privacy.html')),
          _SettingsRow(Icons.description_outlined, 'Terms & Conditions',
              () => _openLegalPage(context, 'terms.html')),
          _SettingsRow(
              Icons.assignment_return_outlined,
              'Refund / Return Policy',
              () => _openLegalPage(context, 'refund-return.html')),
          _SettingsRow(
              Icons.local_shipping_outlined,
              'Shipping / Delivery Policy',
              () => _openLegalPage(context, 'shipping-delivery.html')),
          _SettingsRow(Icons.support_agent_outlined, 'Contact / Support',
              () => _openLegalPage(context, 'contact-support.html')),
          _SettingsRow(Icons.delete_outline, 'Account Deletion Policy',
              () => _openLegalPage(context, 'account-deletion.html')),
        ],
      ),
    );
  }
}

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final rows = [
      ('English', Lang.en),
      ('हिंदी (Hindi)', Lang.hi),
      ('বাংলা (Bengali)', null),
      ('मराठी (Marathi)', null),
      ('தமிழ் (Tamil)', null),
      ('తెలుగు (Telugu)', null),
      ('ગુજરાતી (Gujarati)', null),
      ('ಕನ್ನಡ (Kannada)', null),
      ('ਪੰਜਾਬੀ (Punjabi)', null),
    ];
    return _SimpleSubShell(
      title: 'Language',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          for (final row in rows)
            ListTile(
              title: Text(row.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: row.$2 == lang
                  ? const Icon(Icons.check_circle, color: AppColors.brightBlue)
                  : null,
              onTap: row.$2 == null
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${row.$1} is coming soon.')),
                      )
                  : () {
                      if (row.$2 != lang) {
                        ref.read(langProvider.notifier).toggle();
                      }
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
            ),
        ],
      ),
    );
  }
}

class _SimpleSubShell extends StatelessWidget {
  const _SimpleSubShell(
      {required this.title, required this.child, this.action});

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
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
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

class _BenefitTile extends StatelessWidget {
  const _BenefitTile(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHistoryRow extends StatelessWidget {
  const _WalletHistoryRow(this.title, this.subtitle, this.amount);

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF0FF),
            child: Icon(Icons.receipt_long, color: AppColors.brightBlue),
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
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.blue,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(this.icon, this.title, this.onTap, {this.trailing});

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAF2))),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing!, style: const TextStyle(color: AppColors.muted)),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

ButtonStyle _orangeButton() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.orange,
    padding: const EdgeInsets.all(15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE8EAF2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .035),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}
