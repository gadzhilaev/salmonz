import '../../core/network/api_client.dart';
import '../models/models.dart';

class AddressesRepository {
  AddressesRepository(this._api);

  final ApiClient _api;

  Future<List<AddressModel>> list() async {
    final res = await _api.get('/addresses');
    return asMapList(res.data).map(AddressModel.fromJson).toList();
  }

  Future<AddressModel> get(String id) async {
    final res = await _api.get('/addresses/$id');
    return AddressModel.fromJson(asMap(res.data));
  }

  Future<AddressModel> create({
    String? title,
    required String city,
    required String street,
    required String house,
    String? apartment,
    String? entrance,
    String? floor,
    String? comment,
    bool? isDefault,
  }) async {
    final res = await _api.post(
      '/addresses',
      data: {
        if (title != null) 'title': title,
        'city': city,
        'street': street,
        'house': house,
        if (apartment != null) 'apartment': apartment,
        if (entrance != null) 'entrance': entrance,
        if (floor != null) 'floor': floor,
        if (comment != null) 'comment': comment,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
    return AddressModel.fromJson(asMap(res.data));
  }

  Future<AddressModel> update(
    String id, {
    String? title,
    String? city,
    String? street,
    String? house,
    String? apartment,
    String? entrance,
    String? floor,
    String? comment,
    bool? isDefault,
  }) async {
    final res = await _api.patch(
      '/addresses/$id',
      data: {
        if (title != null) 'title': title,
        if (city != null) 'city': city,
        if (street != null) 'street': street,
        if (house != null) 'house': house,
        if (apartment != null) 'apartment': apartment,
        if (entrance != null) 'entrance': entrance,
        if (floor != null) 'floor': floor,
        if (comment != null) 'comment': comment,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
    return AddressModel.fromJson(asMap(res.data));
  }

  Future<void> delete(String id) async {
    await _api.delete('/addresses/$id');
  }
}
