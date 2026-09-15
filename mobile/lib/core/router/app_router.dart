import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifications/notification_service.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/ai/presentation/ai_screen.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/utility_flows_screen.dart';
import '../../features/offers/presentation/offers_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/products/presentation/brands_screen.dart';
import '../../features/products/presentation/category_screen.dart';
import '../../features/products/presentation/list_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/products/presentation/search_results_screen.dart';
import '../../features/profile/presentation/location_picker_screen.dart';
import '../../features/profile/presentation/account_subpages.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_subpages.dart';
import '../../features/quickbuy/presentation/quick_buy_screen.dart';
import '../../features/styleguide/presentation/style_guide_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final bootstrap = ref.watch(authBootstrapProvider);
  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (bootstrap.isLoading) return null;
      final publicAuthRoute = state.uri.path == '/splash' ||
          state.uri.path == '/login' ||
          state.uri.path == '/otp-login' ||
          state.uri.path == '/forgot-password' ||
          state.uri.path == '/style-guide';
      if (state.uri.path == '/splash') return null;
      if (auth == null && !publicAuthRoute) return '/login';
      if (auth != null && publicAuthRoute) return '/';
      if (state.uri.path == '/admin' && auth?.isAdmin != true) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/otp-login', builder: (_, __) => const OtpLoginScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/style-guide', builder: (_, __) => const StyleGuideScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/bulk-order', builder: (_, __) => const BulkOrderScreen()),
      GoRoute(
          path: '/voice-search', builder: (_, __) => const VoiceSearchScreen()),
      GoRoute(
          path: '/barcode-scan',
          builder: (_, __) => const BarcodeScannerScreen()),
      GoRoute(
          path: '/search',
          builder: (_, s) => SearchResultsScreen(
              initialQuery: s.uri.queryParameters['q'] ?? '')),
      GoRoute(path: '/quick-buy', builder: (_, __) => const QuickBuyScreen()),
      GoRoute(path: '/category', builder: (_, __) => const CategoryScreen()),
      GoRoute(
          path: '/category/:id',
          builder: (_, s) =>
              CategoryScreen(categoryId: s.pathParameters['id'])),
      GoRoute(
          path: '/list/:type',
          builder: (_, s) =>
              ProductListScreen(type: s.pathParameters['type'] ?? 'in-demand')),
      GoRoute(
          path: '/products/:id',
          builder: (_, s) =>
              ProductDetailScreen(productId: s.pathParameters['id'] ?? '')),
      GoRoute(path: '/brands', builder: (_, __) => const BrandsScreen()),
      GoRoute(
          path: '/brands/:name',
          builder: (_, s) => BrandsScreen(brandName: s.pathParameters['name'])),
      GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
      GoRoute(path: '/rewards', builder: (_, __) => const OffersScreen()),
      GoRoute(
          path: '/rewards/history',
          builder: (_, __) => const PointsHistoryScreen()),
      GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
          path: '/checkout/confirmation',
          builder: (_, s) => OrderConfirmationScreen(
                orderId: s.uri.queryParameters['id'] ?? 'VH000000',
                total: s.uri.queryParameters['total'] ?? '',
              )),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(
          path: '/orders/:id',
          builder: (_, s) =>
              OrderDetailScreen(orderId: s.pathParameters['id'] ?? '')),
      GoRoute(
          path: '/orders/:id/tracking',
          builder: (_, s) =>
              OrderTrackingScreen(orderId: s.pathParameters['id'] ?? '')),
      GoRoute(
          path: '/orders/:id/edit',
          builder: (_, s) =>
              EditOrderScreen(orderId: s.pathParameters['id'] ?? '')),
      GoRoute(
          path: '/orders/:id/return',
          builder: (_, s) => OrderActionScreen(
                orderId: s.pathParameters['id'] ?? '',
                action: 'return',
              )),
      GoRoute(
          path: '/orders/:id/exchange',
          builder: (_, s) => OrderActionScreen(
                orderId: s.pathParameters['id'] ?? '',
                action: 'exchange',
              )),
      GoRoute(
          path: '/orders/:id/review',
          builder: (_, s) => OrderActionScreen(
                orderId: s.pathParameters['id'] ?? '',
                action: 'review',
              )),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: '/profile/addresses',
          builder: (_, __) => const AddressesScreen()),
      GoRoute(
          path: '/profile/addresses/new',
          builder: (_, __) => const AddressFormScreen(edit: false)),
      GoRoute(
          path: '/profile/addresses/edit',
          builder: (_, __) => const AddressFormScreen(edit: true)),
      GoRoute(
          path: '/profile/payments',
          builder: (_, __) => const PaymentMethodsScreen()),
      GoRoute(
          path: '/profile/payments/new',
          builder: (_, __) => const AddPaymentMethodScreen()),
      GoRoute(
          path: '/profile/refer', builder: (_, __) => const ReferEarnScreen()),
      GoRoute(
          path: '/profile/help', builder: (_, __) => const HelpSupportScreen()),
      GoRoute(path: '/profile/rate', builder: (_, __) => const RateUsScreen()),
      GoRoute(
          path: '/profile/about',
          builder: (_, __) => const AboutVyparHubScreen()),
      GoRoute(
          path: '/profile/logout',
          builder: (_, __) => const LogoutConfirmScreen()),
      GoRoute(
          path: '/profile/delete-account',
          builder: (_, __) => const AccountDeletionIntroScreen()),
      GoRoute(
          path: '/profile/delete-account/verify',
          builder: (_, __) => const AccountDeletionVerifyScreen()),
      GoRoute(
          path: '/profile/delete-account/confirm',
          builder: (_, __) => const AccountDeletionConfirmScreen()),
      GoRoute(
          path: '/profile/delete-account/progress',
          builder: (_, __) => const AccountDeletingScreen()),
      GoRoute(
          path: '/profile/delete-account/success',
          builder: (_, __) => const AccountDeletedScreen()),
      GoRoute(
          path: '/location', builder: (_, __) => const LocationPickerScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
      GoRoute(
          path: '/profile/settings',
          builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/profile/language',
          builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
    ],
    errorBuilder: (_, __) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
});
