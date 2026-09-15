import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../cart/application/cart_provider.dart';

class BulkOrderScreen extends ConsumerWidget {
  const BulkOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogSnapshotProvider);

    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FlowHeader(title: 'Bulk Order', onBack: () => _safeBack(context)),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (snapshot) {
                  final products = [...snapshot.products]
                    ..sort((a, b) => b.margin.compareTo(a.margin));
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: orangeGradient(),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bigger packs, better margins',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Add fast-moving cartons to your cart and checkout in one go.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const VyparSectionHeader(title: 'Recommended for bulk'),
                      const SizedBox(height: 10),
                      for (final product in products.take(8))
                        VyparCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () => context.go('/products/${product.id}'),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 54,
                                height: 64,
                                child: CatalogImage(product.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${product.pack} - margin ${product.margin}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .add(product.id),
                                child: const Text('ADD'),
                              ),
                            ],
                          ),
                        ),
                      VyparButton.primary(
                        label: 'Review Cart',
                        icon: Icons.shopping_cart_outlined,
                        onPressed: () => context.go('/cart'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FlowHeader(
                title: 'Voice Search', onBack: () => _safeBack(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                children: [
                  VyparCard(
                    color: AppColors.surfaceCream.withValues(alpha: .55),
                    child: const Column(
                      children: [
                        Icon(Icons.mic_none,
                            color: AppColors.primaryAlt, size: 56),
                        SizedBox(height: 12),
                        Text(
                          'Voice search is prepared',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'TODO: connect speech-to-text permission and transcript stream. For now, type what you want to search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Say or type product name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: _search,
                  ),
                  const SizedBox(height: 14),
                  VyparButton.primary(
                    label: 'Search',
                    icon: Icons.arrow_forward,
                    onPressed: () => _search(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showHeader: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FlowHeader(
              title: 'Barcode Scanner',
              onBack: () => _safeBack(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                children: [
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 220,
                            height: 118,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                'Camera scanner stub\nTODO: connect barcode plugin',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter barcode/product code manually',
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    onSubmitted: _search,
                  ),
                  const SizedBox(height: 14),
                  VyparButton.primary(
                    label: 'Find Product',
                    icon: Icons.search,
                    onPressed: () => _search(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
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
        ],
      ),
    );
  }
}

void _safeBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}
