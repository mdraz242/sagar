import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vyparhub_mobile/features/products/data/demo_catalog.dart';
import 'package:vyparhub_mobile/main.dart';
import 'package:vyparhub_mobile/shared/widgets/product_card.dart';

void main() {
  testWidgets('login uses logo, tabs, and hint-only fields', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VyparHubApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.image(const AssetImage('assets/branding/vyparhub_v_mark.png')),
        findsOneWidget);
    expect(find.textContaining('Vypar'), findsOneWidget);
    expect(find.text('Login'), findsAtLeastNWidgets(2));
    expect(find.text('Signup'), findsOneWidget);
    expect(find.text('Sign up'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Employee'), findsNothing);
    expect(find.text('Email or phone number'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Ramesh Sharma'), findsNothing);
    expect(find.text('9876543210'), findsNothing);
  });

  testWidgets('forgot password opens a full reset page', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: VyparHubApp()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot password'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
  });

  testWidgets('product card keeps product image visible on narrow phones',
      (tester) async {
    final product = demoProducts.firstWhere((p) => p.name == 'Coca Cola');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 146,
                height: 348,
                child: ProductCard(product: product),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.image(AssetImage(product.image)), findsOneWidget);
    expect(find.text('Coca Cola'), findsOneWidget);
    expect(find.text('ORDER NOW'), findsOneWidget);
  });

  testWidgets('product card scales for wider Edge preview widths',
      (tester) async {
    final product = demoProducts.firstWhere((p) => p.name == 'Coca Cola');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 190,
                height: 370,
                child: ProductCard(product: product),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.image(AssetImage(product.image)), findsOneWidget);
    expect(find.text('Coca Cola'), findsOneWidget);
  });
}
