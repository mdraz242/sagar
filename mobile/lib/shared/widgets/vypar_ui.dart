import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../features/products/domain/product.dart';
import 'catalog_image.dart';

class VyparCard extends StatelessWidget {
  const VyparCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 16,
    this.color = Colors.white,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

class VyparSectionHeader extends StatelessWidget {
  const VyparSectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'View all',
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onAction != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 15),
            label: Text(actionLabel),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
      ],
    );
  }
}

class VyparButton extends StatelessWidget {
  const VyparButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _variant = _ButtonVariant.primary;

  const VyparButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _variant = _ButtonVariant.secondary;

  const VyparButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _variant = _ButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (_variant) {
      _ButtonVariant.primary => Colors.white,
      _ButtonVariant.secondary => Colors.white,
      _ButtonVariant.ghost => AppColors.secondary,
    };
    final background = switch (_variant) {
      _ButtonVariant.primary => AppColors.primary,
      _ButtonVariant.secondary => AppColors.secondary,
      _ButtonVariant.ghost => Colors.white,
    };
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17),
          const SizedBox(width: 7),
        ],
        Text(label),
      ],
    );

    if (_variant == _ButtonVariant.primary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : orangeGradient(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor:
                onPressed == null ? AppColors.accent : Colors.transparent,
            foregroundColor: foreground,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
      );
    }

    if (_variant == _ButtonVariant.ghost) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child,
    );
  }
}

enum _ButtonVariant { primary, secondary, ghost }

class VyparSearchBar extends StatelessWidget {
  const VyparSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search for "Coca Cola" or more...',
    this.onChanged,
    this.onMic,
    this.onScan,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMic;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onMic,
              icon: const Icon(Icons.mic_none, color: AppColors.primaryAlt),
            ),
            IconButton(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined,
                  color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class VyparCategoryCard extends StatelessWidget {
  const VyparCategoryCard({
    super.key,
    required this.label,
    required this.image,
    required this.onTap,
  });

  final String label;
  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(child: CatalogImage(image)),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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

class VyparProductCard extends StatelessWidget {
  const VyparProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onOrderNow,
    this.quantity = 0,
    this.onIncrement,
    this.onDecrement,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onOrderNow;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final discount = product.mrp <= 0
        ? 0
        : (((product.mrp - product.buyPrice) / product.mrp) * 100).round();
    return VyparCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 92,
                width: double.infinity,
                child: CatalogImage(product.image),
              ),
              if (discount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAlt,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$discount% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          Text(
            product.size,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                money(product.buyPrice),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 5),
              Text(
                money(product.mrp),
                style: const TextStyle(
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: quantity <= 0
                    ? VyparButton.ghost(label: 'Add', onPressed: onAdd)
                    : _QuantityStepper(
                        quantity: quantity,
                        onIncrement: onIncrement ?? onAdd,
                        onDecrement: onDecrement,
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: VyparButton.primary(
                  label: 'Order',
                  onPressed: onOrderNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
          ),
          Text('$quantity',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class VyparOfferCard extends StatelessWidget {
  const VyparOfferCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onUse,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withValues(alpha: .18),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onUse, child: const Text('Use Now')),
            ],
          ),
        ],
      ),
    );
  }
}

class VyparBanner extends StatelessWidget {
  const VyparBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      color: AppColors.surfaceCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 7,
              color: AppColors.primaryAlt,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class VyparEmptyState extends StatelessWidget {
  const VyparEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      color: AppColors.surfaceCream.withValues(alpha: .45),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryAlt, size: 54),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            VyparButton.primary(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class VyparSkeletonList extends StatelessWidget {
  const VyparSkeletonList({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 112),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      child: Row(
        children: [
          const _SkeletonBox(width: 64, height: 64, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                _SkeletonBox(width: 160, height: 11),
                SizedBox(height: 12),
                _SkeletonBox(width: 92, height: 18, radius: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shade = Color.lerp(
          const Color(0xFFF2F4F8),
          const Color(0xFFE7EAF1),
          _controller.value,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: shade,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class VyparBottomNavPreview extends StatelessWidget {
  const VyparBottomNavPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return VyparCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.home, 'Home', true),
          _navIcon(Icons.grid_view, 'Quick Buy', false),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                gradient: orangeGradient(), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          _navIcon(Icons.card_giftcard, 'Rewards', false),
          _navIcon(Icons.shopping_cart, 'Cart', false),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? AppColors.primaryAlt : AppColors.ink),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primaryAlt : AppColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

void showVyparToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ),
  );
}

void goOrToast(BuildContext context, String route, String message) {
  try {
    context.go(route);
  } catch (_) {
    showVyparToast(context, message);
  }
}
