import '../../features/products/data/demo_catalog.dart';
import '../models/catalog_models.dart';
import '../repositories/catalog_repository.dart';

class MockCatalogRepository implements CatalogRepository {
  @override
  Future<List<Category>> getCategories() async => demoCategories;

  @override
  Future<List<Product>> getProducts() async => demoProducts;

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async =>
      productsForCategory(categoryId);

  @override
  Future<Product?> getProductById(String productId) async {
    for (final product in demoProducts) {
      if (product.id == productId) return product;
    }
    return null;
  }
}
