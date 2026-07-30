import '../../core/network/api_client.dart';
import '../models/models.dart';

class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;

  Future<SupportMessageModel> create({
    String? subject,
    required String message,
  }) async {
    final res = await _api.post(
      '/support',
      data: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'message': message,
      },
    );
    return SupportMessageModel.fromJson(asMap(res.data));
  }

  Future<List<SupportMessageModel>> list() async {
    final res = await _api.get('/support');
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return Paginated.fromJson(asMap(data), SupportMessageModel.fromJson).data;
    }
    return asMapList(data).map(SupportMessageModel.fromJson).toList();
  }

  Future<SupportMessageModel> get(String id) async {
    final res = await _api.get('/support/$id');
    return SupportMessageModel.fromJson(asMap(res.data));
  }
}
