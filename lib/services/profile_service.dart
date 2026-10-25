import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/errors.dart';
import '../models/user.dart';

class ProfileService {
  final ApiClient _client;
  ProfileService(this._client);

  Future<User> updateProfile({String? name, String? phone}) async {
    try {
      final res = await _client.dio.patch(
        '/auth/me',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      return User.fromJson(res.data);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }

  Future<User> uploadAvatar(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      final res = await _client.dio.post('/auth/me/avatar', data: formData);
      return User.fromJson(res.data);
    } on DioException catch (e) {
      throw AppError.fromDioException(e);
    }
  }
}
