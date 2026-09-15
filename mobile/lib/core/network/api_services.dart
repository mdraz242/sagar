import 'package:dio/dio.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/products/domain/product.dart';
import 'api_client.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final ShopProfile user;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: ShopProfile.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<bool> isPhoneRegistered(String phone) async {
    final response = await _client.dio.get<dynamic>(
      '/auth/lookup',
      queryParameters: {'phone': phone},
    );
    final data = unwrapData<Map<String, dynamic>>(response);
    return data['registered'] == true;
  }

  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/login',
      data: {
        'phone': phone,
        'password': password,
      },
    );
    return AuthSession.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<String?> requestOtp({
    required String phone,
    String? name,
    String? shopName,
    String? address,
    String? area,
    String? pincode,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/otp/send',
      data: {
        'phone': phone,
        if (name != null && name.isNotEmpty) 'name': name,
        if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
        if (address != null && address.isNotEmpty) 'address': address,
        if (area != null && area.isNotEmpty) 'area': area,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      },
    );
    final data = unwrapData<Map<String, dynamic>>(response);
    return data['devCode'] as String?;
  }

  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String? password,
    String? shopName,
    String? address,
    String? area,
    String? pincode,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/otp/verify',
      data: {
        'phone': phone,
        'code': code,
        if (name != null && name.isNotEmpty) 'name': name,
        if (password != null && password.isNotEmpty) 'password': password,
        if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
        if (address != null && address.isNotEmpty) 'address': address,
        if (area != null && area.isNotEmpty) 'area': area,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      },
    );
    return AuthSession.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _client.dio.post<dynamic>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthSession.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<void> logout() async {
    await _client.dio.post<dynamic>('/auth/logout');
  }
}

class CartApi {
  const CartApi(this._client);

  final ApiClient _client;

  Future<Map<String, int>> getCart() async {
    final response = await _client.dio.get<dynamic>('/cart');
    return _cartMap(unwrapData<Map<String, dynamic>>(response));
  }

  Future<Map<String, int>> add(String cartKey, int quantity) async {
    final parsed = parseCartKey(cartKey);
    final response = await _client.dio.post<dynamic>(
      '/cart/add',
      data: {
        'productId': parsed.productId,
        if (parsed.variantKey != null) 'variantKey': parsed.variantKey,
        'quantity': quantity.abs(),
      },
    );
    return _cartMap(unwrapData<Map<String, dynamic>>(response));
  }

  Future<Map<String, int>> remove(String cartKey, int quantity) async {
    final parsed = parseCartKey(cartKey);
    final response = await _client.dio.post<dynamic>(
      '/cart/remove',
      data: {
        'productId': parsed.productId,
        if (parsed.variantKey != null) 'variantKey': parsed.variantKey,
        'quantity': quantity.abs(),
      },
    );
    return _cartMap(unwrapData<Map<String, dynamic>>(response));
  }

  Map<String, int> _cartMap(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>? ?? const []);
    return {
      for (final item in items)
        _cartKey(
          item['productId'].toString(),
          item['variantKey']?.toString(),
        ): (item['quantity'] as num).toInt(),
    };
  }
}

class Address {
  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.line1,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  final String id;
  final String name;
  final String phone;
  final String line1;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      line1: json['line1']?.toString() ?? json['line_1']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      isDefault: json['is_default'] == true || json['isDefault'] == true,
    );
  }

  String get display => [
        line1,
        area,
        city,
        state,
        pincode,
      ].where((part) => part.isNotEmpty).join(', ');
}

class AddressApi {
  const AddressApi(this._client);

  final ApiClient _client;

  Future<List<Address>> list() async {
    final response = await _client.dio.get<dynamic>('/addresses');
    final data = unwrapData<List<dynamic>>(response);
    return data
        .map((item) => Address.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Address> create(Map<String, dynamic> body) async {
    final response = await _client.dio.post<dynamic>('/addresses', data: body);
    return Address.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<Address> update(String id, Map<String, dynamic> body) async {
    final response =
        await _client.dio.put<dynamic>('/addresses/$id', data: body);
    return Address.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<Address> setDefault(String id) async {
    final response = await _client.dio.patch<dynamic>('/addresses/$id/default');
    return Address.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<void> delete(String id) async {
    await _client.dio.delete<dynamic>('/addresses/$id');
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.itemCount,
    this.items = const [],
    this.address,
    this.statusHistory = const [],
    this.returnRequests = const [],
    this.payment,
  });

  final String id;
  final String status;
  final num total;
  final DateTime? createdAt;
  final int itemCount;
  final List<OrderItemSnapshot> items;
  final Address? address;
  final List<OrderStatusHistory> statusHistory;
  final List<ReturnRequestSummary> returnRequests;
  final OrderPaymentSnapshot? payment;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final history = json['status_history'] as List<dynamic>? ?? const [];
    final requests = json['return_requests'] as List<dynamic>? ?? const [];
    final parsedItems = items
        .map((item) => OrderItemSnapshot.fromJson(item as Map<String, dynamic>))
        .toList();
    final addressJson = json['address'];
    final paymentJson = json['payment'];
    return OrderSummary(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? 'pending',
      total: num.tryParse(json['total'].toString()) ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      itemCount: parsedItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      ),
      items: parsedItems,
      address: addressJson is Map<String, dynamic>
          ? Address.fromJson(addressJson)
          : null,
      statusHistory: history
          .map((item) =>
              OrderStatusHistory.fromJson(item as Map<String, dynamic>))
          .toList(),
      returnRequests: requests
          .map((item) =>
              ReturnRequestSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      payment: paymentJson is Map<String, dynamic>
          ? OrderPaymentSnapshot.fromJson(paymentJson)
          : null,
    );
  }
}

class ReturnRequestSummary {
  const ReturnRequestSummary({
    required this.id,
    required this.requestType,
    required this.status,
    required this.reason,
    required this.refundMethod,
    required this.amount,
    required this.items,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  final String id;
  final String requestType;
  final String status;
  final String reason;
  final String refundMethod;
  final num amount;
  final List<Map<String, dynamic>> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;

  factory ReturnRequestSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['items_json'];
    return ReturnRequestSummary(
      id: json['id'].toString(),
      requestType: json['request_type']?.toString() ?? 'return',
      status: json['status']?.toString() ?? 'requested',
      reason: json['reason']?.toString() ?? '',
      refundMethod: json['refund_method']?.toString() ?? 'wallet',
      amount: num.tryParse(json['amount'].toString()) ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

class OrderPaymentSnapshot {
  const OrderPaymentSnapshot({
    required this.mode,
    required this.status,
    required this.amount,
  });

  final String mode;
  final String status;
  final num amount;

  bool get isPrepaid => mode.isNotEmpty && mode.toLowerCase() != 'cod';

  factory OrderPaymentSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderPaymentSnapshot(
      mode: json['mode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: num.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class OrderStatusHistory {
  const OrderStatusHistory({
    required this.status,
    this.changedAt,
    this.adminId,
  });

  final String status;
  final DateTime? changedAt;
  final String? adminId;

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status']?.toString() ?? '',
      changedAt: DateTime.tryParse(json['changed_at']?.toString() ?? ''),
      adminId: json['admin_id']?.toString(),
    );
  }
}

class OrderItemSnapshot {
  const OrderItemSnapshot({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.mrp,
    required this.buyPrice,
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.pack,
    required this.brand,
  });

  final String id;
  final String productId;
  final int quantity;
  final num mrp;
  final num buyPrice;
  final String name;
  final String imageUrl;
  final String size;
  final String pack;
  final String brand;

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    return OrderItemSnapshot(
      id: json['id']?.toString() ?? '',
      productId:
          json['productId']?.toString() ?? json['product_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      mrp: num.tryParse(json['mrp'].toString()) ?? 0,
      buyPrice:
          num.tryParse((json['buyPrice'] ?? json['buy_price']).toString()) ?? 0,
      name: (product['name'] ?? json['name'] ?? '').toString(),
      imageUrl: (product['imageUrl'] ??
              product['image_url'] ??
              json['imageUrl'] ??
              '')
          .toString(),
      size: (product['size'] ?? json['size'] ?? '').toString(),
      pack: (product['pack'] ?? json['pack'] ?? '').toString(),
      brand: (product['brand'] ?? json['brand'] ?? '').toString(),
    );
  }

  Product toProduct() {
    return Product(
      id: productId,
      categoryId: '',
      name: name.isEmpty ? 'Order item' : name,
      brand: brand,
      size: size,
      pack: pack,
      image: imageUrl,
      mrp: mrp,
      buyPrice: buyPrice,
      stock: 0,
    );
  }
}

class OrderApi {
  const OrderApi(this._client);

  final ApiClient _client;

  Future<List<OrderSummary>> list({int page = 1, int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '/orders',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = unwrapData<Map<String, dynamic>>(response);
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderSummary> create({
    String? addressId,
    required List<Map<String, dynamic>> items,
    String notes = '',
    String? paymentMode,
    String? idempotencyKey,
  }) async {
    final cleanKey = idempotencyKey?.trim();
    final response = await _client.dio.post<dynamic>(
      '/orders',
      data: {
        if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
        'items': items,
        'notes': notes,
        if (paymentMode != null) 'paymentMode': paymentMode,
        if (cleanKey != null && cleanKey.isNotEmpty) 'idempotencyKey': cleanKey,
      },
      options: cleanKey == null || cleanKey.isEmpty
          ? null
          : Options(headers: {'Idempotency-Key': cleanKey}),
    );
    return OrderSummary.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<OrderSummary> get(String id) async {
    final response = await _client.dio.get<dynamic>('/orders/$id');
    return OrderSummary.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<OrderSummary> cancel(String id, {required String reason}) async {
    final response = await _client.dio.post<dynamic>(
      '/orders/$id/cancel',
      data: {'reason': reason},
    );
    return OrderSummary.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<OrderSummary> updateItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.dio.put<dynamic>(
      '/orders/$orderId/items',
      data: {'items': items},
    );
    return OrderSummary.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<void> requestRefund({
    required String orderId,
    required String reason,
    required String refundMethod,
    String requestType = 'return',
    List<Map<String, dynamic>> items = const [],
    String customerNotes = '',
  }) async {
    await _client.dio.post<dynamic>(
      '/orders/$orderId/refund',
      data: {
        'reason': reason,
        'refundMethod': refundMethod,
        'requestType': requestType,
        'items': items,
        if (customerNotes.isNotEmpty) 'customerNotes': customerNotes,
      },
    );
  }
}

class RazorpayOrder {
  const RazorpayOrder({
    required this.keyId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.internalOrderId,
  });

  final String keyId;
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String internalOrderId;

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    return RazorpayOrder(
      keyId: json['keyId'].toString(),
      razorpayOrderId: json['razorpayOrderId'].toString(),
      amount: (json['amount'] as num).toInt(),
      currency: json['currency']?.toString() ?? 'INR',
      internalOrderId: json['internalOrderId'].toString(),
    );
  }
}

class PaymentApi {
  const PaymentApi(this._client);

  final ApiClient _client;

  Future<RazorpayOrder> createRazorpayOrder(String orderId) async {
    final response = await _client.dio.post<dynamic>(
      '/payments/create-order',
      data: {'orderId': orderId},
    );
    return RazorpayOrder.fromJson(unwrapData<Map<String, dynamic>>(response));
  }
}

class ProfileApi {
  const ProfileApi(this._client);

  final ApiClient _client;

  Future<void> registerFcmToken(String token) async {
    await _client.dio.put<dynamic>('/profile', data: {'fcmToken': token});
  }

  Future<void> deleteAccount(String code) async {
    await _client.dio.delete<dynamic>(
      '/profile/account',
      data: {'code': code},
    );
  }
}

class AdminDashboard {
  const AdminDashboard({
    required this.products,
    required this.categories,
    required this.orders,
    required this.revenue,
    required this.lowStock,
  });

  final int products;
  final int categories;
  final int orders;
  final num revenue;
  final int lowStock;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final products = json['products'] as Map<String, dynamic>? ?? const {};
    final categories = json['categories'] as Map<String, dynamic>? ?? const {};
    final orders = json['orders'] as Map<String, dynamic>? ?? const {};
    return AdminDashboard(
      products: (products['count'] as num?)?.toInt() ?? 0,
      categories: (categories['count'] as num?)?.toInt() ?? 0,
      orders: (orders['count'] as num?)?.toInt() ?? 0,
      revenue: num.tryParse(orders['revenue'].toString()) ?? 0,
      lowStock: (products['low_stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminApi {
  const AdminApi(this._client);

  final ApiClient _client;

  Future<AdminDashboard> dashboard() async {
    final response = await _client.dio.get<dynamic>('/admin/dashboard');
    return AdminDashboard.fromJson(unwrapData<Map<String, dynamic>>(response));
  }

  Future<List<Product>> products() async {
    final response = await _client.dio.get<dynamic>('/admin/products');
    final data = unwrapData<List<dynamic>>(response);
    return data
        .map((item) => productFromApi(item as Map<String, dynamic>))
        .toList();
  }
}

class ParsedCartKey {
  const ParsedCartKey(this.productId, this.variantKey);

  final String productId;
  final String? variantKey;
}

ParsedCartKey parseCartKey(String key) {
  final parts = key.split('__');
  return ParsedCartKey(
    parts.first,
    parts.length > 1 ? parts.skip(1).join('__') : null,
  );
}

String _cartKey(String productId, String? variantKey) {
  if (variantKey == null || variantKey.isEmpty) return productId;
  return '${productId}__$variantKey';
}

Product productFromApi(Map<String, dynamic> json) {
  final apiVariants = (json['variants'] as List<dynamic>?)
      ?.map((item) {
        final variant = item as Map<String, dynamic>;
        return ProductVariant(
          id: variant['id']?.toString(),
          productId: variant['productId']?.toString() ??
              variant['product_id']?.toString(),
          size: (variant['size'] ??
                  variant['variantName'] ??
                  variant['variant_name'])
              .toString(),
          pack: (variant['pack'] ?? variant['unit'] ?? '').toString(),
          mrp: num.tryParse(variant['mrp'].toString()) ?? 0,
          buyPrice: num.tryParse((variant['buyPrice'] ??
                      variant['buy_price'] ??
                      variant['sellingPrice'] ??
                      variant['selling_price'])
                  .toString()) ??
              0,
          costPrice: num.tryParse((variant['costPrice'] ??
                      variant['cost_price'] ??
                      variant['buyPrice'] ??
                      variant['buy_price'] ??
                      variant['sellingPrice'] ??
                      variant['selling_price'])
                  .toString()) ??
              0,
          packQuantity: (variant['packQuantity'] as num?)?.toInt() ??
              (variant['pack_quantity'] as num?)?.toInt(),
          stock: (variant['stock'] as num?)?.toInt() ??
              (variant['stockQuantity'] as num?)?.toInt() ??
              (variant['stock_quantity'] as num?)?.toInt(),
          isActive: variant['isActive'] != false &&
              variant['is_active'] != false &&
              (variant['status']?.toString().toLowerCase() ?? 'active') !=
                  'inactive',
        );
      })
      .where((variant) => variant.size.isNotEmpty && variant.isActive)
      .toList();
  final size = (json['size'] ?? '').toString();
  final variants = apiVariants?.isNotEmpty == true
      ? apiVariants
      : size.isNotEmpty
          ? [
              ProductVariant(
                size: size,
                pack: (json['pack'] ?? '').toString(),
                mrp: num.tryParse(json['mrp'].toString()) ?? 0,
                buyPrice: num.tryParse(
                        (json['buyPrice'] ?? json['buy_price']).toString()) ??
                    0,
                costPrice: num.tryParse(
                  (json['costPrice'] ?? json['cost_price']).toString(),
                ),
                stock: (json['stock'] as num?)?.toInt(),
                packQuantity: (json['packQuantity'] as num?)?.toInt() ??
                    (json['pack_quantity'] as num?)?.toInt(),
              ),
            ]
          : null;
  final sortedVariants = variants == null
      ? const <ProductVariant>[]
      : ([...variants]..sort((a, b) {
          final aStock = a.stock ?? 0;
          final bStock = b.stock ?? 0;
          if (aStock > 0 && bStock <= 0) return -1;
          if (aStock <= 0 && bStock > 0) return 1;
          return a.buyPrice.compareTo(b.buyPrice);
        }));
  final displayVariant = sortedVariants.isEmpty ? null : sortedVariants.first;
  final rawMrp = num.tryParse(json['mrp'].toString()) ?? 0;
  final rawBuyPrice =
      num.tryParse((json['buyPrice'] ?? json['buy_price']).toString()) ?? 0;
  final variantMrp = displayVariant?.mrp ?? 0;
  final variantBuyPrice = displayVariant?.buyPrice ?? 0;
  final rawStock = (json['stock'] as num?)?.toInt() ?? 0;
  final effectiveStock = sortedVariants.isEmpty
      ? rawStock
      : sortedVariants.fold<int>(
          0,
          (sum, variant) => sum + (variant.stock ?? 0),
        );

  return Product(
    id: json['id'].toString(),
    categoryId: (json['categoryId'] ??
            json['category_id'] ??
            json['categorySlug'] ??
            json['category_slug'] ??
            '')
        .toString(),
    name: (json['name'] ?? json['name_en'] ?? '').toString(),
    brand: (json['brand'] ?? '').toString(),
    size: displayVariant?.size ?? size,
    pack: displayVariant?.pack ?? (json['pack'] ?? '').toString(),
    image: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    mrp: variantMrp > 0 ? variantMrp : rawMrp,
    buyPrice: variantBuyPrice > 0 ? variantBuyPrice : rawBuyPrice,
    stock: effectiveStock,
    variants: sortedVariants.isEmpty ? variants : sortedVariants,
  );
}
