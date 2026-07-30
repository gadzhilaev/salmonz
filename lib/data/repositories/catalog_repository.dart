import '../../core/network/api_client.dart';
import '../models/models.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<CategoryModel>> getCategories() async {
    final res = await _api.get('/categories');
    return asMapList(res.data).map(CategoryModel.fromJson).toList();
  }

  Future<CategoryModel> getCategory(String idOrSlug) async {
    final res = await _api.get('/categories/$idOrSlug');
    return CategoryModel.fromJson(asMap(res.data));
  }

  Future<Paginated<ProductModel>> getProducts({
    int page = 1,
    int limit = 50,
    String? categoryId,
    String? search,
  }) async {
    final res = await _api.get(
      '/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'q': search,
      },
    );
    return Paginated.fromJson(asMap(res.data), ProductModel.fromJson);
  }

  Future<ProductModel> getProduct(String id) async {
    final res = await _api.get('/products/$id');
    return ProductModel.fromJson(asMap(res.data));
  }

  Future<List<PromotionModel>> getPromotions() async {
    final res = await _api.get('/promotions');
    return asMapList(res.data).map(PromotionModel.fromJson).toList();
  }
}
