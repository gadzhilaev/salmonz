import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/models.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<UserModel> getMe() async {
    final res = await _api.get('/users/me');
    return UserModel.fromJson(asMap(res.data));
  }

  Future<UserModel> updateMe({String? name, String? phone}) async {
    final res = await _api.patch(
      '/users/me',
      data: {if (name != null) 'name': name, if (phone != null) 'phone': phone},
    );
    return UserModel.fromJson(asMap(res.data));
  }

  Future<UserModel> uploadAvatar({
    required String filePath,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final res = await _api.post(
      '/users/me/avatar',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return UserModel.fromJson(asMap(res.data));
  }
}
