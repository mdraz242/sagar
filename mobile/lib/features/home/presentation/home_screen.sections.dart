part of 'home_screen.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
        TextButton.icon(
          onPressed: onViewAll,
          label: const Text('View all'),
          icon: const Icon(Icons.arrow_forward, size: 16),
          iconAlignment: IconAlignment.end,
          style: TextButton.styleFrom(foregroundColor: AppColors.orange),
        ),
      ],
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final items = [...categories.take(11), null];
    return SizedBox(
      height: 224,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .9,
        ),
        itemBuilder: (context, index) {
          final category = items[index];
          if (category == null) {
            return _CategoryTile.more(onTap: () => context.go('/category'));
          }
          return _CategoryTile(category: category);
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category})
      : onTap = null,
        more = false;
  const _CategoryTile.more({required this.onTap})
      : category = null,
        more = true;

  final Category? category;
  final VoidCallback? onTap;
  final bool more;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => context.go('/category/${category!.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: more ? const Color(0xFFF0F4FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Column(
          children: [
            Expanded(
              child: more
                  ? const Icon(Icons.grid_view_rounded,
                      color: AppColors.blue, size: 32)
                  : CatalogImage(category!.image),
            ),
            const SizedBox(height: 5),
            Text(more ? 'More' : category!.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _LiveHomeSections extends StatelessWidget {
  const _LiveHomeSections({
    required this.sections,
    required this.now,
  });

  final List<HomeSection> sections;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final visible = sections.where((section) => section.isVisible(now));
    return Column(
      children: [
        for (final section in visible) ...[
          _SectionHeader(
            title: section.title,
            onViewAll: () => context.go('/list/${section.sectionKey}'),
          ),
          if (section.hasCountdown) ...[
            _FlashCountdown(endsAt: section.endsAt!),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 10),
          _DealsRow(products: section.products),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _FlashCountdown extends StatelessWidget {
  const _FlashCountdown({required this.endsAt});

  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final remaining = endsAt.difference(DateTime.now());
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hours = safe.inHours.toString().padLeft(2, '0');
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.orange, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Flash sale ends in',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              color: AppColors.primaryAlt,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
