import '../../core/network/api_client.dart';
import '../models/models.dart';

class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<OrderModel> create({
    required String addressId,
    required String phone,
    String? comment,
    required List<({String productId, int quantity})> items,
    required String idempotencyKey,
  }) async {
    final res = await _api.post(
      '/orders',
      data: {
        'addressId': addressId,
        'phone': phone,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'items': items
            .map((e) => {'productId': e.productId, 'quantity': e.quantity})
            .toList(),
        'idempotencyKey': idempotencyKey,
      },
    );
    return OrderModel.fromJson(asMap(res.data));
  }

  Future<List<OrderModel>> list() async {
    final res = await _api.get('/orders');
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return Paginated.fromJson(asMap(data), OrderModel.fromJson).data;
    }
    return asMapList(data).map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> get(String id) async {
    final res = await _api.get('/orders/$id');
    return OrderModel.fromJson(asMap(res.data));
  }
}
