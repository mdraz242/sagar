import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/api_services.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/catalog_image.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboard>((ref) {
  return ref.watch(adminApiProvider).dashboard();
});

final adminProductsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminApiProvider).products();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);
    final products = ref.watch(adminProductsProvider);
    return AppShell(
      child: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(apiErrorMessage(error))),
        data: (stats) => LayoutBuilder(
          builder: (context, constraints) {
            final pad = Responsive.horizontalPadding(constraints);
            return ListView(
              padding: EdgeInsets.all(pad),
              children: [
                const Text('Admin Dashboard',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: Responsive.gridColumns(constraints),
                  childAspectRatio: 1.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stat('Products', '${stats.products}'),
                    _stat('Categories', '${stats.categories}'),
                    _stat('Revenue', money(stats.revenue)),
                    _stat('Low Stock', '${stats.lowStock}'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Recently added products',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                products.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (error, _) => Text(apiErrorMessage(error)),
                  data: (items) => Column(
                    children: [
                      ...items.take(8).map(
                            (p) => ListTile(
                              leading: CatalogImage(p.image, width: 42),
                              title: Text(p.name),
                              subtitle: Text('Stock: ${p.stock}'),
                              trailing: Text(money(p.buyPrice)),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
