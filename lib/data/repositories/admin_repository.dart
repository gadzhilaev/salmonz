import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/models.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  // --- Categories ---

  Future<List<CategoryModel>> listCategories({int page = 1, int limit = 100}) async {
    final res = await _api.get(
      '/admin/categories',
      queryParameters: {'page': page, 'limit': limit},
    );
    return Paginated.fromJson(asMap(res.data), CategoryModel.fromJson).data;
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/categories', data: body);
    return CategoryModel.fromJson(asMap(res.data));
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/categories/$id', data: body);
    return CategoryModel.fromJson(asMap(res.data));
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/admin/categories/$id');
  }

  // --- Products ---

  Future<List<ProductModel>> listProducts({
    int page = 1,
    int limit = 100,
    String? categoryId,
  }) async {
    final res = await _api.get(
      '/admin/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
    return Paginated.fromJson(asMap(res.data), ProductModel.fromJson).data;
  }

  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/products', data: body);
    return ProductModel.fromJson(asMap(res.data));
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/products/$id', data: body);
    return ProductModel.fromJson(asMap(res.data));
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/admin/products/$id');
  }

  // --- Promotions ---

  Future<List<PromotionModel>> listPromotions({int page = 1, int limit = 100}) async {
    final res = await _api.get(
      '/admin/promotions',
      queryParameters: {'page': page, 'limit': limit},
    );
    return Paginated.fromJson(asMap(res.data), PromotionModel.fromJson).data;
  }

  Future<PromotionModel> createPromotion(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/promotions', data: body);
    return PromotionModel.fromJson(asMap(res.data));
  }

  Future<PromotionModel> updatePromotion(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/promotions/$id', data: body);
    return PromotionModel.fromJson(asMap(res.data));
  }

  Future<void> deletePromotion(String id) async {
    await _api.delete('/admin/promotions/$id');
  }

  // --- Orders ---

  Future<List<OrderModel>> listOrders({int page = 1, int limit = 50}) async {
    final res = await _api.get(
      '/admin/orders',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return Paginated.fromJson(asMap(data), OrderModel.fromJson).data;
    }
    return asMapList(data).map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> getOrder(String id) async {
    final res = await _api.get('/admin/orders/$id');
    return OrderModel.fromJson(asMap(res.data));
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    final res = await _api.patch(
      '/admin/orders/$id/status',
      data: {'status': status},
    );
    return OrderModel.fromJson(asMap(res.data));
  }

  // --- Support ---

  Future<List<SupportMessageModel>> listSupport({int page = 1, int limit = 50}) async {
    final res = await _api.get(
      '/admin/support',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return Paginated.fromJson(asMap(data), SupportMessageModel.fromJson).data;
    }
    return asMapList(data).map(SupportMessageModel.fromJson).toList();
  }

  Future<SupportMessageModel> updateSupportStatus(String id, String status) async {
    final res = await _api.patch(
      '/admin/support/$id/status',
      data: {'status': status},
    );
    return SupportMessageModel.fromJson(asMap(res.data));
  }

  // --- Users ---

  Future<List<UserModel>> listUsers({int page = 1, int limit = 50}) async {
    final res = await _api.get(
      '/admin/users',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return Paginated.fromJson(asMap(data), UserModel.fromJson).data;
    }
    return asMapList(data).map(UserModel.fromJson).toList();
  }

  // --- Uploads ---

  Future<UploadResult> uploadProductImage({
    required String filePath,
    required String filename,
  }) =>
      _upload('/admin/uploads/product', filePath, filename);

  Future<UploadResult> uploadCategoryImage({
    required String filePath,
    required String filename,
  }) =>
      _upload('/admin/uploads/category', filePath, filename);

  Future<UploadResult> uploadPromotionImage({
    required String filePath,
    required String filename,
  }) =>
      _upload('/admin/uploads/promotion', filePath, filename);

  Future<UploadResult> _upload(String path, String filePath, String filename) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final res = await _api.post(
      path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return UploadResult.fromJson(asMap(res.data));
  }
}
