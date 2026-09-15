import '../models/catalog_models.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();
  Future<List<Product>> getProducts();
  Future<List<Product>> getProductsByCategory(String categoryId);
  Future<Product?> getProductById(String productId);
}
