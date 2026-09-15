import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../cart/application/cart_provider.dart';

class ShopProfile {
  const ShopProfile({
    required this.id,
    required this.name,
    required this.shopName,
    required this.phone,
    required this.address,
    required this.area,
    required this.role,
    this.pincode = '',
  });

  final String id;
  final String name;
  final String shopName;
  final String phone;
  final String address;
  final String area;
  final String role;
  final String pincode;

  bool get isAdmin => role == 'admin' || role == 'super_admin';

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'VyparHub Retailer',
      shopName: json['shopName']?.toString() ??
          json['shop_name']?.toString() ??
          'VyparHub Store',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Address pending',
      area: json['area']?.toString() ?? 'Area pending',
      pincode: json['pincode']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shopName': shopName,
      'shop_name': shopName,
      'phone': phone,
      'address': address,
      'area': area,
      'pincode': pincode,
      'role': role,
    };
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, ShopProfile?>(
  (ref) => AuthNotifier(ref),
);

final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).restore();
});

class AuthNotifier extends StateNotifier<ShopProfile?> {
  AuthNotifier(this.ref) : super(null);

  final Ref ref;

  Future<bool> isPhoneRegistered(String phone) async {
    if (AppConfig.useMockData) return phone == '9876543210';
    return ref.read(authApiProvider).isPhoneRegistered(phone);
  }

  Future<void> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      if (phone != '9876543210' || password != 'Demo@123') {
        throw const ApiException('Invalid phone or password');
      }
      state = ShopProfile(
        id: 'mock-user',
        name: 'Demo Retailer',
        shopName: 'VyparHub Store',
        phone: phone,
        address: 'Address pending',
        area: 'Area pending',
        role: 'customer',
      );
      return;
    }

    final session = await ref.read(authApiProvider).login(
          phone: phone,
          password: password,
        );
    await ref.read(tokenStorageProvider).save(
          session.accessToken,
          session.refreshToken,
          user: session.user.toJson(),
        );
    state = session.user;
    await ref.read(cartProvider.notifier).loadFromServer();
    await _registerNotifications();
  }

  Future<String?> requestOtp({
    required String phone,
    String? name,
    String? shopName,
    String? address,
    String? area,
    String? pincode,
  }) async {
    if (AppConfig.useMockData) return '123456';
    return ref.read(authApiProvider).requestOtp(
          phone: phone,
          name: name,
          shopName: shopName,
          address: address,
          area: area,
          pincode: pincode,
        );
  }

  Future<void> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String? password,
    String? shopName,
    String? address,
    String? area,
    String? pincode,
  }) async {
    if (AppConfig.useMockData) {
      if (code.trim() != '123456') throw const ApiException('Invalid OTP');
      state = ShopProfile(
        id: 'mock-user',
        name: name?.isNotEmpty == true ? name! : 'VyparHub Retailer',
        shopName: shopName?.isNotEmpty == true ? shopName! : 'VyparHub Store',
        phone: phone,
        address: address?.isNotEmpty == true ? address! : 'Address pending',
        area: area?.isNotEmpty == true ? area! : 'Area pending',
        pincode: pincode ?? '',
        role: 'customer',
      );
      return;
    }

    final session = await ref.read(authApiProvider).verifyOtp(
          phone: phone,
          code: code,
          name: name,
          password: password,
          shopName: shopName,
          address: address,
          area: area,
          pincode: pincode,
        );
    await ref.read(tokenStorageProvider).save(
          session.accessToken,
          session.refreshToken,
          user: session.user.toJson(),
        );
    state = session.user;
    await ref.read(cartProvider.notifier).loadFromServer();
    await _registerNotifications();
  }

  Future<void> restore() async {
    if (AppConfig.useMockData || state != null) return;
    final storage = ref.read(tokenStorageProvider);
    final cached = await storage.cachedUserProfile();
    if (cached != null) {
      state = ShopProfile.fromJson(cached);
    }

    final refresh = await storage.refreshToken();
    if (refresh == null || refresh.isEmpty) {
      if (cached != null) await _registerNotifications();
      return;
    }

    try {
      final session = await ref.read(authApiProvider).refresh(refresh);
      await storage.save(
        session.accessToken,
        session.refreshToken,
        user: session.user.toJson(),
      );
      state = session.user;
      await ref.read(cartProvider.notifier).loadFromServer();
      await _registerNotifications();
    } catch (_) {
      // Keep the retailer signed in through Render cold starts, spotty mobile
      // networks, and temporary API failures. Explicit logout/delete is the
      // only place that clears secure storage.
      if (cached != null) {
        await _registerNotifications();
      }
    }
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!AppConfig.useMockData && !localOnly) {
      try {
        await ref.read(authApiProvider).logout();
      } catch (_) {}
    }
    await ref.read(tokenStorageProvider).clear();
    ref.read(cartProvider.notifier).clear();
    state = null;
  }

  Future<void> deleteAccount(String code) async {
    if (!AppConfig.useMockData) {
      await ref.read(profileApiProvider).deleteAccount(code);
    }
    await ref.read(tokenStorageProvider).clear();
    ref.read(cartProvider.notifier).clear();
    state = null;
  }

  Future<void> _registerNotifications() async {
    if (AppConfig.useMockData) return;
    try {
      final token =
          await NotificationService(FirebaseMessaging.instance).initialize();
      if (token != null && token.isNotEmpty) {
        await ref.read(profileApiProvider).registerFcmToken(token);
      }
    } catch (_) {
      // Firebase is optional in local builds until google-services.json exists.
    }
  }
}
