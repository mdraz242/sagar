import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/navigation.dart';
import '../../../data/repositories/catalog_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';
import '../../../shared/widgets/vypar_ui.dart';
import '../../products/domain/product.dart';

part 'orders_screen.list_and_detail.dart';
part 'orders_screen.edit.dart';
part 'orders_screen.action_return.dart';
part 'orders_screen.tracking.dart';
part 'orders_screen.invoice.dart';
part 'orders_screen.shell.dart';

final ordersProvider = FutureProvider.autoDispose<List<OrderSummary>>((ref) {
  return ref.watch(orderApiProvider).list();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderSummary, String>((ref, id) {
  return ref.watch(orderApiProvider).get(id);
});

final orderStatusFilterProvider =
    StateProvider.autoDispose<String>((_) => 'All Orders');

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final products =
        ref.watch(catalogSnapshotProvider).valueOrNull?.products ?? const [];
    final filter = GoRouterState.of(context).uri.queryParameters['filter'];
    final action = GoRouterState.of(context).uri.queryParameters['action'];
    if (filter != null) {
      final label = _filterLabel(filter);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(orderStatusFilterProvider.notifier).state = label;
      });
    }

    return _OrderSubShell(
      title: 'My Orders',
      action: TextButton(
        onPressed: () => context.go('/orders'),
        child: const Text('View All'),
      ),
      child: orders.when(
        loading: () => const VyparSkeletonList(),
        error: (error, _) {
          if (AppConfig.useMockData) {
            return _OrderList(
              orders: _demoOrders(),
              products: products,
              action: action,
            );
          }
          return _RetryState(
            title: 'Could not load orders',
            message: apiErrorMessage(error),
            onRetry: () => ref.invalidate(ordersProvider),
          );
        },
        data: (orders) => _OrderList(
          orders: orders,
          products: products,
          action: action,
        ),
      ),
    );
  }
}
