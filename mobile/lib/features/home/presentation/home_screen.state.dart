part of 'home_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final search = TextEditingController();
  String query = '';
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogSnapshotProvider);

    return AppShell(
      child: catalog.when(
        loading: () => const VyparSkeletonList(itemCount: 6),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: VyparEmptyState(
              icon: Icons.wifi_off_outlined,
              title: 'Could not load dashboard',
              subtitle: error.toString(),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(catalogSnapshotProvider),
            ),
          ),
        ),
        data: (snapshot) {
          final products = snapshot.products;
          final categories = snapshot.categories;
          final deals = _topDeals(products).take(8).toList();
          final brands = _brands(products).take(6).toList();
          final trimmedQuery = query.trim();
          final suggestions = _suggestions(snapshot, trimmedQuery);
          final lang = ref.watch(langProvider);
          final shop = ref.watch(authProvider);
          final savedAddress = ref.watch(headerAddressesProvider).valueOrNull;
          final defaultAddress = _homeDefaultAddress(savedAddress);
          final deliveryQuery = _homeDeliveryQuery(shop, defaultAddress);
          final deliveryContext =
              ref.watch(deliveryContextProvider(deliveryQuery)).valueOrNull;
          final deliveryArea = deliveryContext?.area ??
              (deliveryQuery.area.isEmpty ? 'your area' : deliveryQuery.area);
          final serviceable = deliveryContext?.serviceable ?? false;
          final deliveryEta = serviceable
              ? (deliveryContext?.etaLabel ?? '2 hours')
              : 'Not serviceable';
          final configuredSections =
              ref.watch(homeSectionsProvider).valueOrNull ?? const [];
          final now = DateTime.now();
          final visibleSections = configuredSections
              .where((section) => section.isVisible(now))
              .toList();
          final railSections = visibleSections.isNotEmpty
              ? visibleSections
              : [
                  HomeSection(
                    id: 'fallback-top-deals',
                    sectionKey: 'top_deals',
                    title: 'Top Deals for You',
                    products: deals,
                  ),
                ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final pad = Responsive.horizontalPadding(constraints);
              return ListView(
                padding: EdgeInsets.fromLTRB(pad, 10, pad, 96),
                children: [
                  _SearchBox(
                    controller: search,
                    query: trimmedQuery,
                    suggestions: suggestions,
                    onChanged: (value) => setState(() => query = value),
                    onClear: () {
                      search.clear();
                      setState(() => query = '');
                    },
                    onSelected: (suggestion) {
                      search.text = suggestion.title;
                      search.selection = TextSelection.collapsed(
                        offset: suggestion.title.length,
                      );
                      setState(() => query = '');
                      context.go(suggestion.route);
                    },
                  ),
                  if (trimmedQuery.isNotEmpty)
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .55,
                      child: Center(
                        child: Text(
                          suggestions.isEmpty
                              ? 'No result found for "$trimmedQuery"'
                              : 'Select a result above',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 14),
                    _HeroPanel(
                      products: deals,
                      etaLabel: deliveryEta,
                      serviceable: serviceable,
                    ),
                    const SizedBox(height: 14),
                    const _PromiseStrip(),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title:
                          _copy(lang, 'Shop by Category', 'कैटेगरी से खरीदें'),
                      onViewAll: () => context.go('/category'),
                    ),
                    const SizedBox(height: 10),
                    _CategoryScroller(categories: categories),
                    const SizedBox(height: 18),
                    if (railSections.isEmpty)
                      _SectionHeader(
                        title: _copy(
                            lang, 'Top Deals for You', 'आपके लिए टॉप डील्स'),
                        onViewAll: () => context.go('/offers'),
                      ),
                    const SizedBox(height: 10),
                    _LiveHomeSections(sections: railSections, now: now),
                    const SizedBox(height: 18),
                    _BulkBanner(products: deals),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: _copy(lang, 'Top Brands', 'टॉप ब्रांड्स'),
                      onViewAll: () => context.go('/brands'),
                    ),
                    const SizedBox(height: 10),
                    _BrandScroller(brands: brands, products: products),
                    const SizedBox(height: 18),
                    Text(
                      _copy(
                        lang,
                        'Why Shop with VyparHub?',
                        'VyparHub से क्यों खरीदें?',
                      ),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _WhyGrid(area: deliveryArea, serviceable: serviceable),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SearchSuggestion {
  const _SearchSuggestion({
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
