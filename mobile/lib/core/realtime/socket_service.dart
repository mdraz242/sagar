import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../data/repositories/catalog_providers.dart';
import '../../features/cart/application/cart_provider.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../config/app_config.dart';
import '../network/api_providers.dart';

final customerSocketServiceProvider = Provider<CustomerSocketService>((ref) {
  final service = CustomerSocketService(ref);
  ref.onDispose(service.disconnect);
  return service;
});

final customerSocketBootstrapProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(customerSocketServiceProvider);
  await service.connect();
});

class CustomerSocketService {
  CustomerSocketService(this.ref);

  final Ref ref;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (AppConfig.useMockData || _socket?.connected == true) return;

    final token = await ref.read(tokenStorageProvider).accessToken();
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse(AppConfig.apiBaseUrl);
    final origin = uri.replace(path: '', query: '', fragment: '').toString();
    _socket?.dispose();
    _socket = io.io(
      '$origin/customer',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {})
      ..onDisconnect((_) {})
      ..onConnectError((_) {})
      ..on('order.created', _refreshOrders)
      ..on('order.status_changed', _refreshOrder)
      ..on('refund.status_changed', _refreshOrders)
      ..on('wallet.transaction_created', _refreshOrders)
      ..on('product.created', _refreshCatalog)
      ..on('product.updated', _refreshCatalog)
      ..on('product.deleted', _refreshCatalog)
      ..on('product.stock_changed', _refreshCatalog)
      ..on('product.price_changed', _refreshCatalog)
      ..on('brand.deleted', _refreshCatalog)
      ..on('brand.updated', _refreshCatalog)
      ..on('category.deleted', _refreshCatalog)
      ..on('category.updated', _refreshCatalog)
      ..on('catalog.updated', _refreshCatalog)
      ..on('coupon.created', _refreshCatalog)
      ..on('coupon.updated', _refreshCatalog)
      ..on('coupon.deleted', _refreshCatalog)
      ..on('banner.created', _refreshCatalog)
      ..on('banner.updated', _refreshCatalog)
      ..on('banner.deleted', _refreshCatalog)
      ..on('home_section.updated', _refreshHomeSections)
      ..on('home_section.deleted', _refreshHomeSections)
      ..on('delivery_zone.updated', _refreshDeliveryContext)
      ..on('delivery_zone.deleted', _refreshDeliveryContext)
      ..connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void _refreshCatalog(dynamic _) {
    ref.invalidate(catalogSnapshotProvider);
    ref.invalidate(pagedProductsProvider);
    ref.invalidate(productsByCategoryProvider);
    ref.invalidate(cartLinesProvider);
    ref.invalidate(unavailableCartLinesProvider);
  }

  void _refreshHomeSections(dynamic _) {
    ref.invalidate(homeSectionsProvider);
  }

  void _refreshDeliveryContext(dynamic _) {
    ref.invalidate(deliveryContextProvider);
  }

  void _refreshOrders(dynamic payload) {
    ref.invalidate(ordersProvider);
    final orderId = _orderIdFrom(payload);
    if (orderId != null) ref.invalidate(orderDetailProvider(orderId));
  }

  void _refreshOrder(dynamic payload) {
    _refreshOrders(payload);
  }

  String? _orderIdFrom(dynamic payload) {
    if (payload is Map && payload['orderId'] != null) {
      return payload['orderId'].toString();
    }
    return null;
  }
}
