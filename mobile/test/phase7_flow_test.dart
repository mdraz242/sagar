import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vyparhub_mobile/core/network/api_providers.dart';
import 'package:vyparhub_mobile/data/repositories/catalog_repository.dart';
import 'package:vyparhub_mobile/features/auth/application/auth_provider.dart';
import 'package:vyparhub_mobile/features/cart/application/cart_provider.dart';
import 'package:vyparhub_mobile/features/checkout/presentation/checkout_screen.dart';
import 'package:vyparhub_mobile/features/products/domain/product.dart';
import 'package:vyparhub_mobile/main.dart';

const _testCategory = Category(
  id: 'phase7-cat',
  name: 'Phase 7 Category',
  image: 'assets/images/products/parle-g.jpg',
  tintHex: '#FFE9D6',
);

const _testVariant = ProductVariant(
  size: '2 kg',
  pack: '6',
  mrp: 220,
  buyPrice: 170,
);

const _testProduct = Product(
  id: 'phase7-product',
  categoryId: 'phase7-cat',
  name: 'Phase 7 Product',
  brand: 'PhaseBrand',
  size: '1 kg',
  pack: '12',
  image: 'assets/images/products/parle-g.jpg',
  mrp: 120,
  buyPrice: 90,
  stock: 50,
  variants: [_testVariant],
);

class _FakeCatalogRepository implements CatalogRepository {
  const _FakeCatalogRepository();

  @override
  Future<List<Category>> getCategories() async => const [_testCategory];

  @override
  Future<List<Product>> getProducts() async => const [_testProduct];

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async =>
      categoryId == _testCategory.id ? const [_testProduct] : const [];

  @override
  Future<Product?> getProductById(String productId) async =>
      productId == _testProduct.id ? _testProduct : null;
}

void main() {
  testWidgets('login OTP flow authenticates a mock customer', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const VyparHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email or phone number').first,
      '9876543210',
    );
    final loginButton = find.widgetWithText(FilledButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Development OTP: 1234'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Enter OTP'), '1234');
    final verifyButton = find.widgetWithText(FilledButton, 'Verify OTP');
    await tester.ensureVisible(verifyButton);
    await tester.tap(verifyButton);
    await tester.pumpAndSettle();

    expect(container.read(authProvider)?.phone, '9876543210');
  });

  test('cart provider tracks variant product quantities and totals', () async {
    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          const _FakeCatalogRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final cartKey = variantCartKey(_testProduct, _testVariant);
    await container.read(cartProvider.notifier).add(cartKey, 2);

    expect(container.read(cartProvider), {cartKey: 2});
    final lines = cartLines(container.read(cartProvider), const [_testProduct]);
    expect(lines, hasLength(1));
    expect(lines.first.variant?.size, '2 kg');
    expect(lines.first.buyPrice, 170);
    expect(cartBuy(container.read(cartProvider), const [_testProduct]), 340);
  });

  testWidgets('checkout transitions from address to COD order placed',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          const _FakeCatalogRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(cartProvider.notifier).add(_testProduct.id, 1);
    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, __) => const Scaffold(body: Text('Cart')),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Address'), 'Shop 1');
    await tester.tap(find.text('Continue to Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Payment'), findsOneWidget);
    await tester.tap(find.text('Cash on Delivery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Order Placed'), findsAtLeastNWidgets(1));
    expect(container.read(cartProvider), isEmpty);
  });
}
