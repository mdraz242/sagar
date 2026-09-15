import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vyparhub_mobile/core/theme/app_theme.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/utils/navigation.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/product_card.dart';
import '../domain/product.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final cfg = _config(type, lang);
    final catalog = ref.watch(catalogSnapshotProvider);
    return AppShell(
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (snapshot) {
          final products = _listProducts(snapshot.products, type);
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: cfg.gradient),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () => goBackOr(context, '/'),
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white)),
                      CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: .2),
                          child: Icon(cfg.icon, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(cfg.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                            Text(cfg.subtitle,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(30)),
                          child: Text('${products.length} ${tr('items', lang)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900))),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = Responsive.gridColumns(constraints);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 112),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: constraints.maxWidth < 380 ? 344 : 360,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: products[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _ListConfig _config(String type, Lang lang) {
    switch (type) {
      case 'high-margin':
        return _ListConfig(
            tr('highMargin', lang),
            lang == Lang.hi ? 'सबसे अच्छा मुनाफा' : 'Best profit margins',
            Icons.trending_up,
            const LinearGradient(
                colors: [AppColors.secondary, AppColors.secondary]));
      case 'local-area':
        return _ListConfig(
            lang == Lang.hi ? 'लोकल एरिया' : 'Local Area',
            lang == Lang.hi
                ? 'आपके इलाके में लोकप्रिय'
                : 'Popular in your area',
            Icons.location_on,
            const LinearGradient(
                colors: [AppColors.secondary, AppColors.secondary]));
      case 'best-prices':
        return _ListConfig(
            lang == Lang.hi ? 'सबसे अच्छे दाम' : 'Best Prices',
            lang == Lang.hi
                ? 'कम कीमत वाले प्रोडक्ट पहले'
                : 'Lowest buy prices first',
            Icons.sell_outlined,
            const LinearGradient(
                colors: [Color(0xFF022EA7), Color(0xFF8FA0D7)]));
      case 'in-demand':
      default:
        return _ListConfig(
            tr('inDemand', lang),
            lang == Lang.hi
                ? 'अभी सबसे ज्यादा बिक रहा'
                : 'Top selling right now',
            Icons.local_fire_department,
            const LinearGradient(
                colors: [Color(0xFFFFB36B), Color(0xFFFF7A3D)]));
    }
  }
}

List<Product> _listProducts(List<Product> products, String type) {
  final sorted = [...products];
  switch (type) {
    case 'high-margin':
      sorted.sort((a, b) => b.margin.compareTo(a.margin));
      return sorted;
    case 'local-area':
      sorted.sort((a, b) => (b.margin + b.stock).compareTo(a.margin + a.stock));
      return sorted.where((p) => p.stock >= 20).toList();
    case 'best-prices':
      sorted.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
      return sorted;
    case 'in-demand':
    default:
      sorted.sort((a, b) => (b.margin + b.stock).compareTo(a.margin + a.stock));
      return sorted;
  }
}

class _ListConfig {
  const _ListConfig(this.title, this.subtitle, this.icon, this.gradient);
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
}
