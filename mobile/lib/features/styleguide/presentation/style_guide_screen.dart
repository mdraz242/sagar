import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/products/data/demo_catalog.dart';
import '../../../shared/widgets/vypar_ui.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleProduct = demoProducts.firstWhere(
      (product) => product.name.toLowerCase().contains('coca'),
      orElse: () => demoProducts.first,
    );
    final sampleCategory = demoCategories.first;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text('VyparHub UI Kit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const VyparSectionHeader(
              title: 'Color Tokens',
              actionLabel: 'Phase 1',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _ColorSwatch('Primary', AppColors.primary),
                _ColorSwatch('Primary Alt', AppColors.primaryAlt),
                _ColorSwatch('Secondary', AppColors.secondary),
                _ColorSwatch('Accent', AppColors.accent),
                _ColorSwatch('Cream', AppColors.surfaceCream),
                _ColorSwatch('Ink', AppColors.ink),
                _ColorSwatch('Muted', AppColors.muted),
                _ColorSwatch('Success', AppColors.success),
              ],
            ),
            const SizedBox(height: 22),
            const VyparSectionHeader(title: 'Buttons'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: VyparButton.primary(
                    label: 'Shop Now',
                    icon: Icons.arrow_forward,
                    onPressed: () => showVyparToast(context, 'Primary tapped'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: VyparButton.secondary(
                    label: 'View Deals',
                    onPressed: () =>
                        showVyparToast(context, 'Secondary tapped'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            VyparButton.ghost(
              label: 'Ghost Action',
              icon: Icons.tune,
              onPressed: () => showVyparToast(context, 'Ghost tapped'),
            ),
            const SizedBox(height: 22),
            const VyparSectionHeader(title: 'Search'),
            const SizedBox(height: 10),
            VyparSearchBar(
              onChanged: (_) {},
              onMic: () => showVyparToast(context, 'Voice search ready'),
              onScan: () => showVyparToast(context, 'Scanner ready'),
            ),
            const SizedBox(height: 22),
            const VyparSectionHeader(title: 'Retail Components'),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: VyparCategoryCard(
                      label: sampleCategory.name,
                      image: sampleCategory.image,
                      onTap: () => showVyparToast(context, 'Category tapped'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VyparBanner(
                      title: 'Free delivery progress',
                      subtitle: 'Add Rs 299 more to unlock free delivery.',
                      progress: .62,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 255,
              child: VyparProductCard(
                product: sampleProduct,
                quantity: 1,
                onAdd: () => showVyparToast(context, 'Added to cart'),
                onIncrement: () => showVyparToast(context, 'Quantity added'),
                onDecrement: () => showVyparToast(context, 'Quantity removed'),
                onOrderNow: () => showVyparToast(context, 'Order flow opened'),
              ),
            ),
            const SizedBox(height: 22),
            const VyparSectionHeader(title: 'Offer Card'),
            const SizedBox(height: 10),
            VyparOfferCard(
              icon: Icons.local_offer_outlined,
              title: '5% Instant Discount',
              subtitle: 'On HDFC Cards. Min. order Rs 999',
              badge: '5% OFF',
              onUse: () => showVyparToast(context, 'Offer applied'),
            ),
            const SizedBox(height: 12),
            VyparEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No products yet',
              subtitle: 'When admin adds products, they appear in this layout.',
              actionLabel: 'Go Home',
              onAction: () => context.go('/'),
            ),
            const SizedBox(height: 22),
            const VyparSectionHeader(title: 'Bottom Navigation'),
            const SizedBox(height: 10),
            const VyparBottomNavPreview(),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
