import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/product_card.dart';
import '../domain/product.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.categoryId;
  }

  @override
  void didUpdateWidget(covariant CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      selectedCategoryId = widget.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogSnapshotProvider);

    return AppShell(
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (snapshot) {
          if (snapshot.categories.isEmpty) {
            return const Center(child: Text('No categories available.'));
          }

          final activeId = selectedCategoryId?.isNotEmpty == true
              ? selectedCategoryId!
              : snapshot.categories.first.id;
          final activeCategory = snapshot.categories.firstWhere(
            (category) => category.id == activeId,
            orElse: () => snapshot.categories.first,
          );
          final productsAsync =
              ref.watch(productsByCategoryProvider(activeCategory.id));

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => goBackOr(context, '/'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        activeCategory.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () => context.go('/search'),
                      icon: const Icon(Icons.search, color: AppColors.blue),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final leftRailWidth = constraints.maxWidth >= 700
                        ? 112.0
                        : constraints.maxWidth < 360
                            ? 74.0
                            : 86.0;
                    final columns = Responsive.gridColumns(
                      BoxConstraints(
                        maxWidth: constraints.maxWidth - leftRailWidth,
                      ),
                    );
                    final gridWidth = constraints.maxWidth - leftRailWidth;
                    final cardExtent = gridWidth < 290
                        ? 338.0
                        : gridWidth < 420
                            ? 305.0
                            : 325.0;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: leftRailWidth,
                          color: const Color(0xFFFAFBFE),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 108),
                            itemCount: snapshot.categories.length,
                            itemBuilder: (context, index) {
                              final category = snapshot.categories[index];
                              final active = category.id == activeCategory.id;
                              return _CategoryRailTile(
                                category: category,
                                active: active,
                                compact: constraints.maxWidth < 360,
                                onTap: () {
                                  setState(
                                    () => selectedCategoryId = category.id,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: productsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, _) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  error.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.primaryAlt,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            data: (products) => products.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        'No products in ${activeCategory.name}.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 10, 10, 108),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisExtent: cardExtent,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) =>
                                        ProductCard(product: products[index]),
                                  ),
                          ),
                        ),
                      ],
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
}

class _CategoryRailTile extends StatelessWidget {
  const _CategoryRailTile({
    required this.category,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final Category category;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: active ? Colors.white : const Color(0xFFFAFBFE),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 8,
          vertical: 9,
        ),
        child: Column(
          children: [
            Container(
              height: compact ? 46 : 54,
              width: compact ? 46 : 54,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.surfaceCream.withValues(alpha: .65)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.primaryAlt : AppColors.border,
                ),
              ),
              child: CatalogImage(category.image),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                color: active ? AppColors.primaryAlt : AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
