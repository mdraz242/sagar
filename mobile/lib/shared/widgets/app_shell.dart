import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/translations.dart';
import '../../core/network/api_providers.dart';
import '../../core/network/api_services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/api_catalog_repository.dart';
import '../../data/repositories/catalog_providers.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/cart/application/cart_provider.dart';

final headerAddressesProvider = FutureProvider.autoDispose<List<Address>>(
  (ref) => ref.watch(addressApiProvider).list(),
);

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, this.showHeader = true});

  final Widget child;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(authProvider);
    final lang = ref.watch(langProvider);
    final cartCount =
        ref.watch(cartProvider).values.fold<int>(0, (a, b) => a + b);
    final path = GoRouterState.of(context).uri.path;
    const maxWidth = 480.0;

    return Scaffold(
      extendBody: false,
      backgroundColor: const Color(0xFFE7E9F1),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: ColoredBox(
            color: AppColors.bg,
            child: Column(
              children: [
                if (showHeader) AppHeader(shop: shop, lang: lang),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: BottomNav(
            activeIndex: _idx(path),
            cartCount: cartCount,
            homeLabel: tr('home', lang),
            quickBuyLabel: _shellCopy(lang, 'Quick Buy', 'जल्दी खरीदें'),
            aiLabel: _shellCopy(lang, 'AI Help', 'AI मदद'),
            ordersLabel: _shellCopy(lang, 'My Orders', 'मेरे ऑर्डर'),
            cartLabel: tr('cart', lang),
          ),
        ),
      ),
    );
  }

  int _idx(String path) {
    if (path.startsWith('/quick-buy') || path.startsWith('/category')) return 1;
    if (path.startsWith('/ai')) return 2;
    if (path.startsWith('/orders')) return 3;
    if (path.startsWith('/cart')) return 4;
    return 0;
  }
}

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key, required this.shop, required this.lang});

  final ShopProfile? shop;
  final Lang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = shop?.name.trim().isNotEmpty == true
        ? shop!.name.trim().substring(0, 1).toUpperCase()
        : 'U';
    final savedAddress = ref.watch(headerAddressesProvider).valueOrNull;
    final defaultAddress = _defaultAddress(savedAddress);
    final deliveryQuery = _deliveryQuery(shop, defaultAddress);
    final deliveryContext =
        ref.watch(deliveryContextProvider(deliveryQuery)).valueOrNull;
    final deliveryArea = deliveryContext?.area ?? deliveryQuery.area;
    final deliveryText = deliveryContext?.deliveryText ??
        (deliveryQuery.pincode.isEmpty
            ? tr('deliveryIn', lang)
            : 'Checking delivery area...');

    return Material(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: _Wordmark()),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go('/wallet'),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9D6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Rs 0 ${tr('wallet', lang)}',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => context.go('/notifications'),
                    icon: const Icon(
                      Icons.notifications_none,
                      color: AppColors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go('/profile'),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: AppColors.orange,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            LocationBar(
              area: deliveryArea,
              deliveryText: deliveryText,
              languageLabel: lang == Lang.hi ? 'EN' : 'HI',
              onTap: () => context.go('/location'),
              onLanguageTap: () => ref.read(langProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}

Address? _defaultAddress(List<Address>? addresses) {
  if (addresses == null || addresses.isEmpty) return null;
  final defaults = addresses.where((address) => address.isDefault);
  return defaults.isNotEmpty ? defaults.first : addresses.first;
}

String _deliveryArea(ShopProfile? shop, Address? address) {
  final fromAddress = [
    address?.city,
    address?.area,
    address?.line1,
  ].whereType<String>().map((part) => part.trim()).firstWhere(
        (part) => part.isNotEmpty,
        orElse: () => '',
      );
  if (fromAddress.isNotEmpty) return fromAddress;

  final profileArea = shop?.area.trim() ?? '';
  if (profileArea.isNotEmpty && profileArea != 'Area pending') {
    return profileArea;
  }
  final profileAddress = shop?.address.trim() ?? '';
  if (profileAddress.isNotEmpty && profileAddress != 'Address pending') {
    return profileAddress;
  }
  return 'Area pending';
}

DeliveryLocationQuery _deliveryQuery(ShopProfile? shop, Address? address) {
  final area = _deliveryArea(shop, address);
  final city = address?.city.trim() ?? '';
  final pincode = (address?.pincode.trim().isNotEmpty == true
          ? address!.pincode.trim()
          : shop?.pincode.trim()) ??
      '';
  return DeliveryLocationQuery(
    area: area == 'Area pending' ? '' : area,
    city: city,
    pincode: pincode,
  );
}

class LocationBar extends StatelessWidget {
  const LocationBar({
    super.key,
    required this.area,
    required this.deliveryText,
    required this.languageLabel,
    required this.onTap,
    required this.onLanguageTap,
  });

  final String area;
  final String deliveryText;
  final String languageLabel;
  final VoidCallback onTap;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: orangeGradient(),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: .18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '$area - $deliveryText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onLanguageTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    languageLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeIndex,
    required this.cartCount,
    required this.homeLabel,
    required this.quickBuyLabel,
    required this.aiLabel,
    required this.ordersLabel,
    required this.cartLabel,
  });

  final int activeIndex;
  final int cartCount;
  final String homeLabel;
  final String quickBuyLabel;
  final String aiLabel;
  final String ordersLabel;
  final String cartLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: homeLabel,
              active: activeIndex == 0,
              onTap: () => context.go('/'),
            ),
            _NavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: quickBuyLabel,
              active: activeIndex == 1,
              onTap: () => context.go('/quick-buy'),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: InkWell(
                  onTap: () => context.go('/ai'),
                  customBorder: const CircleBorder(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: orangeGradient(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: .35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        aiLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: activeIndex == 2
                              ? AppColors.orange
                              : AppColors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: ordersLabel,
              active: activeIndex == 3,
              onTap: () => context.go('/orders'),
            ),
            _NavItem(
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart,
              label: cartLabel,
              active: activeIndex == 4,
              badge: cartCount,
              onTap: () => context.go('/cart'),
            ),
          ],
        ),
      ),
    );
  }
}

String _shellCopy(Lang lang, String en, String hi) => lang == Lang.hi ? hi : en;

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/branding/vyparhub_v_mark.png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Vypar',
                      style: TextStyle(color: AppColors.blue),
                    ),
                    TextSpan(
                      text: 'Hub',
                      style: TextStyle(color: AppColors.orange),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  height: .96,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Makers seh Market tak',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF5A6072),
                  fontSize: 8.5,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.orange : AppColors.blue;
    final iconWidget = Icon(active ? activeIcon : icon, color: color, size: 24);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                label: Text('$badge'),
                isLabelVisible: badge > 0,
                backgroundColor: AppColors.orange,
                child: iconWidget,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
