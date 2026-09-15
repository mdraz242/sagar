import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../auth/application/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final name = user?.name ?? 'VyparHub Retailer';
    final phone = user?.phone ?? '';
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';

    return AppShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: orangeGradient(),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: .24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            phone.isEmpty ? user?.shopName ?? '' : '+91 $phone',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/profile/settings'),
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => context.go('/notifications'),
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _ProfileStat(
                        icon: Icons.account_balance_wallet_outlined,
                        value: 'Rs 0',
                        label: 'Wallet',
                        onTap: () => context.go('/wallet'),
                      ),
                      _ProfileStat(
                        icon: Icons.auto_awesome,
                        value: '2,450',
                        label: 'Points',
                        onTap: () => context.go('/rewards/history'),
                      ),
                      _ProfileStat(
                        icon: Icons.confirmation_number_outlined,
                        value: '12',
                        label: 'Coupons',
                        onTap: () => context.go('/offers'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MenuCard(
            rows: [
              _MenuRowData(
                Icons.location_on_outlined,
                'My Addresses',
                'Manage delivery locations',
                () => context.go('/profile/addresses'),
              ),
              _MenuRowData(
                Icons.card_giftcard_outlined,
                'Rewards',
                'Points, offers and coupons',
                () => context.go('/rewards'),
              ),
              _MenuRowData(
                Icons.credit_card_outlined,
                'Payment Methods',
                'Cash, UPI and cards',
                () => context.go('/profile/payments'),
              ),
              _MenuRowData(
                Icons.group_add_outlined,
                'Refer & Earn',
                'Earn Rs 200',
                () => context.go('/profile/refer'),
              ),
              _MenuRowData(
                Icons.favorite_border,
                'Wishlist',
                'Saved products',
                () => context.go('/wishlist'),
              ),
              _MenuRowData(
                Icons.help_outline,
                'Help & Support',
                'We are here to help',
                () => context.go('/profile/help'),
              ),
              _MenuRowData(
                Icons.star_border,
                'Rate Us',
                'Share your feedback',
                () => context.go('/profile/rate'),
              ),
              _MenuRowData(
                Icons.info_outline,
                'About VyparHub',
                'Makers seh Market tak',
                () => context.go('/profile/about'),
              ),
              _MenuRowData(
                Icons.delete_outline,
                'Account Deletion',
                'Permanently delete your account',
                () => context.go('/profile/delete-account'),
                danger: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.orange),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () => context.go('/profile/logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Icon(icon, color: AppColors.orange, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.rows});

  final List<_MenuRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (final row in rows)
            Column(
              children: [
                ListTile(
                  leading: Icon(
                    row.icon,
                    color: row.danger ? AppColors.primaryAlt : AppColors.blue,
                  ),
                  title: Text(
                    row.title,
                    style: TextStyle(
                      color: row.danger ? AppColors.primaryAlt : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(row.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: row.onTap,
                ),
                if (row != rows.last)
                  const Divider(height: 1, indent: 56, endIndent: 12),
              ],
            ),
        ],
      ),
    );
  }
}

class _MenuRowData {
  const _MenuRowData(
    this.icon,
    this.title,
    this.subtitle,
    this.onTap, {
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE8EAF2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .045),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
