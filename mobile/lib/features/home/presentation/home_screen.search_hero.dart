part of 'home_screen.dart';

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.query,
    required this.suggestions,
    required this.onChanged,
    required this.onClear,
    required this.onSelected,
  });

  final TextEditingController controller;
  final String query;
  final List<_SearchSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<_SearchSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search for "Coca Cola" or more...',
            prefixIcon: const Icon(Icons.search, color: AppColors.blue),
            suffixIcon: query.isEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/voice-search'),
                        icon:
                            const Icon(Icons.mic_none, color: AppColors.orange),
                      ),
                      IconButton(
                        onPressed: () => context.go('/barcode-scan'),
                        icon: const Icon(Icons.document_scanner_outlined,
                            color: AppColors.blue),
                      ),
                    ],
                  )
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
          ),
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
                                horizontal: 14, vertical: 10),
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
                                      Text(suggestion.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800)),
                                      Text(suggestion.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: suggestion.isCategory
                                                  ? AppColors.orange
                                                  : AppColors.brightBlue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.products,
    required this.etaLabel,
    required this.serviceable,
  });
  final List<Product> products;
  final String etaLabel;
  final bool serviceable;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff003B93),
            Color(0xff0058C7),
            Color(0xff0A6BEF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// Rain texture
          Image.asset(
            "assets/images/background1.png",
            fit: BoxFit.fill,
            height: 350,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 22),
            child: Row(
              children: [
                /// LEFT SIDE
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "IN OFFER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: .9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "MEGA SALE",
                        style: TextStyle(
                          color: Color(0xffffd400),
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          height: .9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(text: "UP TO "),
                            TextSpan(
                              text: "40%",
                              style: TextStyle(
                                color: Color(0xffffd400),
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                            TextSpan(text: " OFF"),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xff153C91),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => context.go('/list/in-demand'),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text(
                          "Shop Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                /// RIGHT SIDE
                // Expanded(
                //   flex: 5,
                //   child: Align(
                //     alignment: Alignment.bottomRight,
                //     child: Opacity(
                //       opacity: .7,
                //       child: Image.asset(
                //         "assets/images/banner_products.png",
                //         fit: BoxFit.cover,
                //         height: 350,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromiseStrip extends ConsumerWidget {
  const _PromiseStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final items = [
      (
        Icons.electric_moped,
        lang == Lang.hi ? 'तेज\nडिलीवरी' : 'Express\nDelivery',
        () => context.go('/list/in-demand'),
      ),
      (
        Icons.sell,
        lang == Lang.hi ? 'सबसे अच्छे\nदाम' : 'Best\nPrices',
        () => context.go('/list/best-prices'),
      ),
      (
        Icons.inventory_2,
        lang == Lang.hi ? 'बल्क\nऑर्डर' : 'Bulk\nOrder',
        () => context.go('/bulk-order'),
      ),
      (
        Icons.refresh,
        lang == Lang.hi ? 'आसान\nरिटर्न' : 'Easy\nReturns',
        () => context.go('/orders?filter=Delivered&action=return'),
      ),
      (
        Icons.verified_user,
        lang == Lang.hi ? '100%\nअसली' : '100%\nOriginal',
        () => context.go('/profile/about'),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _softCard(),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                onTap: item.$3,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Icon(item.$1, color: AppColors.orange, size: 24),
                    const SizedBox(height: 6),
                    Text(item.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            height: 1.12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
