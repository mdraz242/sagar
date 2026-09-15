import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  NotificationService(this._messaging, {FlutterLocalNotificationsPlugin? local})
      : _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const _channel = AndroidNotificationChannel(
    'order_updates',
    'Order updates',
    description: 'Notifications for VyparHub order status changes',
    importance: Importance.high,
  );

  Future<String?> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title'];
      final body = notification?.body ?? message.data['body'];
      if (title == null && body == null) return;

      _local.show(
        id: message.hashCode,
        title: title ?? 'VyparHub',
        body: body ?? '',
        payload: jsonEncode(message.data),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_updates',
            'Order updates',
            channelDescription:
                'Notifications for VyparHub order status changes',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRemoteMessageTap(initialMessage);
      });
    }

    return _messaging.getToken();
  }

  static void _handleRemoteMessageTap(RemoteMessage message) {
    _openOrderTracking(message.data);
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final data = jsonDecode(payload);
    if (data is Map<String, dynamic>) _openOrderTracking(data);
  }

  static void _openOrderTracking(Map<String, dynamic> data) {
    final orderId = data['orderId']?.toString();
    if (orderId == null || orderId.isEmpty) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    context.go('/orders/$orderId/tracking');
  }
}
