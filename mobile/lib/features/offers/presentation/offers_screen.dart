import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/vypar_ui.dart';

enum OfferTab { all, points, coupons }

final offerTabProvider = StateProvider<OfferTab>((_) => OfferTab.all);

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products =
        ref.watch(catalogSnapshotProvider).valueOrNull?.products ?? const [];
    final tab = ref.watch(offerTabProvider);
    final offers = _offers
        .where((offer) => tab == OfferTab.all || offer.tab == tab)
        .toList();

    return AppShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
        children: [
          const Text(
            'Rewards',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _PointsCard(onHistory: () => context.go('/rewards/history')),
          const SizedBox(height: 16),
          _EarnPointsCard(),
          const SizedBox(height: 16),
          _OfferTabs(tab: tab),
          const SizedBox(height: 12),
          for (final offer in offers)
            _OfferTile(
              offer: offer,
              onUse: () => _useOffer(context, offer),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Special Rewards',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/rewards/history'),
                child: const Text('View all'),
              ),
            ],
          ),
          _SpecialReward(
              productName: products.isEmpty ? null : products.first.name),
          const SizedBox(height: 10),
          _SpecialReward(
            productName:
                products.length > 3 ? products[3].name : 'Aashirvaad Atta',
            target: 5000,
            points: 2450,
            reward: '250 Points',
          ),
        ],
      ),
    );
  }

  void _useOffer(BuildContext context, _Offer offer) {
    Clipboard.setData(ClipboardData(text: offer.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${offer.code} copied. Apply it at checkout.'),
        action: SnackBarAction(
          label: 'Cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }
}

class PointsHistoryScreen extends StatelessWidget {
  const PointsHistoryScreen({super.key});

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
                        context.go('/rewards');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: AppColors.blue),
                  ),
                  const Expanded(
                    child: Text(
                      'Points History',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                children: [
                  const _HistorySummary(),
                  const SizedBox(height: 14),
                  for (final tx in _history)
                    _HistoryTile(
                      icon: tx.icon,
                      title: tx.title,
                      subtitle: tx.subtitle,
                      points: tx.points,
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

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.onHistory});

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: brandGradient(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vypar Points',
                    style: TextStyle(color: Colors.white70)),
                const Text(
                  '2,450',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('= Rs 24.50', style: TextStyle(color: Colors.white)),
                const Spacer(),
                OutlinedButton(
                  onPressed: onHistory,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('View History'),
                ),
              ],
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppColors.primaryAlt,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.card_giftcard, color: Colors.white, size: 58),
          ),
        ],
      ),
    );
  }
}

class _EarnPointsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VyparCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How to earn points',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              _EarnTile(
                Icons.savings_outlined,
                'Rs 1 Spend',
                '= 1 Point',
                () => _showSpendInfo(context),
              ),
              const SizedBox(width: 10),
              _EarnTile(
                Icons.rate_review_outlined,
                'Write a Review',
                '= 25 Points',
                () => context.go('/profile/rate'),
              ),
              const SizedBox(width: 10),
              _EarnTile(
                Icons.group_add_outlined,
                'Refer a Friend',
                '= 100 Points',
                () => context.go('/profile/refer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSpendInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Earn as you order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every Rs 1 spent on completed VyparHub orders adds 1 Vypar Point. Points can unlock future rewards and coupons.',
              ),
              const SizedBox(height: 16),
              VyparButton.primary(
                label: 'Start Shopping',
                onPressed: () => context.go('/quick-buy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarnTile extends StatelessWidget {
  const _EarnTile(this.icon, this.title, this.subtitle, this.onTap);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.orange),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferTabs extends ConsumerWidget {
  const _OfferTabs({required this.tab});

  final OfferTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<OfferTab>(
      segments: const [
        ButtonSegment(value: OfferTab.all, label: Text('All Offers')),
        ButtonSegment(value: OfferTab.points, label: Text('Points')),
        ButtonSegment(value: OfferTab.coupons, label: Text('Coupons')),
      ],
      selected: {tab},
      showSelectedIcon: false,
      onSelectionChanged: (value) {
        ref.read(offerTabProvider.notifier).state = value.first;
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.surfaceCream,
        selectedForegroundColor: AppColors.primaryAlt,
        foregroundColor: AppColors.blue,
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.onUse});

  final _Offer offer;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return VyparOfferCard(
      icon: offer.icon,
      title: offer.title,
      subtitle: offer.subtitle,
      badge: offer.badge,
      onUse: onUse,
    );
  }
}

class _SpecialReward extends StatelessWidget {
  const _SpecialReward({
    this.productName,
    this.target = 3000,
    this.points = 2450,
    this.reward = '100 Points',
  });

  final String? productName;
  final int target;
  final int points;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.redeem, color: AppColors.brightBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  'For your next ${productName ?? 'order'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (points / target).clamp(0, 1),
                    minHeight: 7,
                    color: AppColors.orange,
                    backgroundColor: const Color(0xFFEAF0FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points / $target',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.card_giftcard, color: AppColors.orange, size: 46),
        ],
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: brandGradient(),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Available Points\n2,450',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
          Text('Rs 24.50', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int points;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF0FF),
            child: Icon(icon, color: AppColors.brightBlue),
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
          Text(
            points > 0 ? '+$points' : '$points',
            style: TextStyle(
              color: points > 0 ? AppColors.success : AppColors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

const _offers = [
  _Offer(
    OfferTab.coupons,
    Icons.percent,
    '5% Instant Discount',
    'Use code VYPAR5 on orders above Rs999',
    '5% OFF',
    'VYPAR5',
  ),
  _Offer(
    OfferTab.points,
    Icons.account_balance_wallet_outlined,
    '10% Cashback',
    'Redeem 500 points to unlock cashback',
    '10% OFF',
    'POINT500',
  ),
  _Offer(
    OfferTab.coupons,
    Icons.local_shipping_outlined,
    'Free Delivery',
    'Use on orders above Rs999',
    'FREE',
    'FREEDEL',
  ),
  _Offer(
    OfferTab.points,
    Icons.card_giftcard_outlined,
    'Reward Booster',
    'Earn 2x points on home care packs today',
    '2X',
    'BOOST2X',
  ),
];

const _history = [
  _RewardTx(
      Icons.shopping_bag_outlined, 'Order reward', 'Order #VH123456', 120),
  _RewardTx(Icons.rate_review_outlined, 'Review bonus', 'Rated VyparHub', 25),
  _RewardTx(
      Icons.group_add_outlined, 'Referral reward', 'Friend first order', 100),
  _RewardTx(Icons.local_offer_outlined, 'Coupon redeemed', 'Used VYPAR50', -50),
];

class _Offer {
  const _Offer(
    this.tab,
    this.icon,
    this.title,
    this.subtitle,
    this.badge,
    this.code,
  );

  final OfferTab tab;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final String code;
}

class _RewardTx {
  const _RewardTx(this.icon, this.title, this.subtitle, this.points);

  final IconData icon;
  final String title;
  final String subtitle;
  final int points;
}
