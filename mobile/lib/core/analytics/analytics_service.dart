import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;
  Future<void> logScreen(String name) =>
      _analytics.logScreenView(screenName: name);
  Future<void> logAddToCart(String productId, int quantity) =>
      _analytics.logEvent(
          name: 'add_to_cart',
          parameters: {'product_id': productId, 'quantity': quantity});
  Future<void> logOrderPlaced(num total) =>
      _analytics.logEvent(name: 'order_placed', parameters: {'total': total});
}
