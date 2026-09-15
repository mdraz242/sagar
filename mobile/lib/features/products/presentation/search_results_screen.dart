import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/vypar_ui.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogSnapshotProvider);

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
                  const Expanded(
                    child: Text(
                      'Search Products',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: VyparSearchBar(
                controller: _controller,
                hintText: 'Search for "Coca Cola" or more...',
                onChanged: _onChanged,
                onMic: () => context.go('/voice-search'),
                onScan: () => context.go('/barcode-scan'),
              ),
            ),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (snapshot) {
                  final normalized = _query.trim().toLowerCase();
                  final products = normalized.isEmpty
                      ? snapshot.products
                      : snapshot.products.where((product) {
                          return product.name
                                  .toLowerCase()
                                  .contains(normalized) ||
                              product.brand
                                  .toLowerCase()
                                  .contains(normalized) ||
                              product.size.toLowerCase().contains(normalized) ||
                              product.pack.toLowerCase().contains(normalized);
                        }).toList();

                  if (products.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: VyparEmptyState(
                        icon: Icons.search_off,
                        title: 'No matching products',
                        subtitle: 'Try another product, brand, or pack size.',
                        actionLabel: 'Browse categories',
                        onAction: () => context.go('/category'),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = Responsive.gridColumns(constraints);
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 108),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent:
                              constraints.maxWidth < 380 ? 344 : 360,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) =>
                            ProductCard(product: products[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }
}
