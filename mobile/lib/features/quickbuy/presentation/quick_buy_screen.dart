import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../cart/application/cart_provider.dart';
import '../../products/domain/product.dart';

class QuickBuyScreen extends ConsumerStatefulWidget {
  const QuickBuyScreen({super.key});

  @override
  ConsumerState<QuickBuyScreen> createState() => _QuickBuyScreenState();
}

class _QuickBuyScreenState extends ConsumerState<QuickBuyScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogSnapshotProvider);

    return AppShell(
      child: catalog.when(
        data: (snapshot) {
          final query = _searchController.text.trim().toLowerCase();
          final suggestions = _quickSuggestions(snapshot, query);
          final products = query.isEmpty
              ? snapshot.products.take(5).toList()
              : snapshot.products
                  .where(
                    (product) =>
                        product.name.toLowerCase().contains(query) ||
                        product.brand.toLowerCase().contains(query),
                  )
                  .take(20)
                  .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quick Buy',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () => context.go('/cart'),
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _QuickSearchBox(
                controller: _searchController,
                query: query,
                suggestions: suggestions,
                onChanged: (_) => setState(() {}),
                onSelected: (suggestion) {
                  _searchController.text = suggestion.title;
                  _searchController.selection = TextSelection.collapsed(
                    offset: suggestion.title.length,
                  );
                  setState(() {});
                  context.go(suggestion.route);
                },
              ),
              const SizedBox(height: 20),
              VyparSectionHeader(
                title: query.isEmpty ? 'Buy Again' : 'Search Results',
                onAction: () => context.go('/list/in-demand'),
              ),
              const SizedBox(height: 10),
              if (products.isEmpty)
                VyparEmptyState(
                  icon: Icons.search_off,
                  title: 'No matching products',
                  subtitle: 'Try a product name, brand, or category.',
                  actionLabel: 'Browse categories',
                  onAction: () => context.go('/category'),
                )
              else
                for (final product in products)
                  _QuickProductRow(product: product),
              const SizedBox(height: 18),
              VyparSectionHeader(
                title: 'Categories',
                onAction: () => context.go('/category'),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.categories.take(8).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 92,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final category = snapshot.categories[index];
                  return VyparCategoryCard(
                    label: category.name,
                    image: category.image,
                    onTap: () => context.go('/category/${category.id}'),
                  );
                },
              ),
              const SizedBox(height: 18),
              VyparCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.content_paste_go_outlined,
                      color: AppColors.primaryAlt,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paste from clipboard',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Copy a product list from anywhere',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => showVyparToast(
                        context,
                        'Clipboard import is prepared for bulk ordering.',
                      ),
                      child: const Text('Paste'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: VyparButton.primary(
                  label: 'View Cart',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () => context.go('/cart'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 108),
          children: [
            VyparEmptyState(
              icon: Icons.wifi_off_outlined,
              title: 'Catalog unavailable',
              subtitle: error.toString(),
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(catalogSnapshotProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchBox extends StatelessWidget {
  const _QuickSearchBox({
    required this.controller,
    required this.query,
    required this.suggestions,
    required this.onChanged,
    required this.onSelected,
  });

  final TextEditingController controller;
  final String query;
  final List<_QuickSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<_QuickSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VyparSearchBar(
          controller: controller,
          hintText: 'Search or paste product name',
          onChanged: onChanged,
          onMic: () => context.go('/voice-search'),
          onScan: () => context.go('/barcode-scan'),
        ),
        if (query.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border.all(color: const Color(0xFFE8E9F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No result found for "$query"'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final suggestion in suggestions)
                        InkWell(
                          onTap: () => onSelected(suggestion),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: CatalogImage(suggestion.image),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggestion.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        suggestion.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: suggestion.isCategory
                                              ? AppColors.primaryAlt
                                              : AppColors.secondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _QuickProductRow extends ConsumerWidget {
  const _QuickProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = product.variants ?? const <ProductVariant>[];
    final hasVariants = variants.length > 1;
    final cart = canonicalizeCart(ref.watch(cartProvider), [product]);
    final qty = hasVariants
        ? variants.fold<int>(
            0,
            (sum, variant) =>
                sum + (cart[variantCartKey(product, variant)] ?? 0),
          )
        : cart[product.id] ?? 0;
    return VyparCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 44, height: 56, child: CatalogImage(product.image)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  product.size,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                Text(
                  '${hasVariants ? 'From ' : ''}${money(product.buyPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          qty == 0
              ? OutlinedButton(
                  onPressed: () async {
                    if (hasVariants) {
                      showProductVariantPicker(context, product);
                      return;
                    }
                    await ref.read(cartProvider.notifier).add(product.id);
                    if (context.mounted) {
                      showVyparToast(context, '${product.name} added');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('ADD'),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.blue),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: hasVariants
                            ? () => showProductVariantPicker(context, product)
                            : () => ref
                                .read(cartProvider.notifier)
                                .add(product.id, -1),
                        icon: const Icon(Icons.remove,
                            color: AppColors.blue, size: 18),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: hasVariants
                            ? () => showProductVariantPicker(context, product)
                            : () =>
                                ref.read(cartProvider.notifier).add(product.id),
                        icon: const Icon(Icons.add,
                            color: AppColors.blue, size: 18),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

List<_QuickSuggestion> _quickSuggestions(dynamic snapshot, String query) {
  if (query.isEmpty) return const [];
  final categoryById = {
    for (final Category category in snapshot.categories) category.id: category,
  };
  final products = snapshot.products
      .where((Product product) =>
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.size.toLowerCase().contains(query))
      .take(6)
      .map((product) {
    final category = categoryById[product.categoryId];
    return _QuickSuggestion(
      title: product.name,
      subtitle: category == null ? product.brand : 'in ${category.name}',
      image: product.image,
      route: '/products/${product.id}',
      isCategory: false,
    );
  });
  final categories = snapshot.categories
      .where((Category category) => category.name.toLowerCase().contains(query))
      .take(3)
      .map((category) => _QuickSuggestion(
            title: category.name,
            subtitle: 'Category',
            image: category.image,
            route: '/category/${category.id}',
            isCategory: true,
          ));
  return List<_QuickSuggestion>.from([...products, ...categories].take(8));
}

class _QuickSuggestion {
  const _QuickSuggestion({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.route,
    required this.isCategory,
  });

  final String title;
  final String subtitle;
  final String image;
  final String route;
  final bool isCategory;
}
