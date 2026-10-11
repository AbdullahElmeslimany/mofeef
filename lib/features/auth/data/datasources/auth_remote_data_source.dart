import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password,
      {String deviceName = 'flutter-mobile'});
  Future<UserModel> register(Map<String, dynamic> data);
  Future<UserModel> getProfile();
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> logout();
  Future<void> deleteAccount();
  Future<void> forgotPassword(String email);
  Future<String> resendVerificationEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<UserModel> login(String email, String password,
      {String deviceName = 'flutter-mobile'}) async {
    Response response;
    try {
      log('🌐 Attempting login for $email at ${ApiEndpoints.login}');
      response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      log('Login response: ${response.data}'); // Log the response data for debugging
    } on DioException catch (e) {
      log('❌ DioException in login: ${e.message}, type: ${e.type}, error: ${e.error}, response: ${e.response?.data}');
      throw ServerFailure.fromDioException(e);
    } catch (e) {
      log('❌ Unexpected error in login: $e');
      throw ServerFailure(e.toString());
    }

    dynamic rawData = response.data;
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

    if (rawData is Map<String, dynamic>) {
      final status = rawData['status'];
      final code = rawData['code']?.toString();
      final msg = rawData['message']?.toString();

      // Check if API returned status 0 or error code or HTTP error status
      if (status == 0 ||
          status == false ||
          response.statusCode != 200 ||
          (code != null && code != 'success' && code != '200')) {
        String errorMsg =
            msg ?? 'فشل تسجيل الدخول، يرجى التأكد من البيانات المدخلة';

        if (code == 'email_not_verified' ||
            (msg != null &&
                (msg.toLowerCase().contains('verify your email') ||
                    msg.contains('التحقق من بريدك')))) {
          errorMsg = msg ?? 'يرجى التحقق من بريدك الإلكتروني قبل تسجيل الدخول.';
        } else if (code == 'invalid_credentials' ||
            msg == 'Password is not correct' ||
            (msg != null &&
                msg.toLowerCase().contains('password is not correct'))) {
          errorMsg = 'كلمة المرور أو البريد الإلكتروني غير صحيح';
        } else if (code == 'account_not_allowed' ||
            (msg != null && msg.contains("account type isn't supported"))) {
          errorMsg =
              'هذا الحساب مخصص للإدارة أو المرشدين ولا يمكن استخدامه في تطبيق المسافرين';
        } else if (rawData['errors'] is Map) {
          final errMap = rawData['errors'] as Map;
          final first = errMap.values.firstOrNull;
          if (first is List && first.isNotEmpty) {
            errorMsg = first.first.toString();
          } else if (first != null) {
            errorMsg = first.toString();
          }
        }

        log('❌ Server rejected login: code=$code, status=$status, message=$errorMsg');
        throw ServerFailure(errorMsg, response.statusCode);
      }

      // Check if user and token exist in response
      final token = rawData['access_token'] ??
          rawData['token'] ??
          (rawData['user'] is Map ? rawData['user']['token'] : null);

      if (token == null || token.toString().isEmpty) {
        throw ServerFailure(msg ?? 'لم يتم استلام رمز الدخول من الخادم');
      }

      return UserModel.fromJson(rawData);
    }

    throw ServerFailure('استجابة غير صحيحة من الخادم');
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) async {
    Response response;
    try {
      response = await _dio.post(
        ApiEndpoints.register,
        data: data,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      log('Register response: ${response.data}');
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    } catch (e) {
      throw ServerFailure(e.toString());
    }

    dynamic resData = response.data;
    if (resData is String) {
      try {
        resData = jsonDecode(resData);
      } catch (_) {}
    }

    if (resData is Map<String, dynamic>) {
      final status = resData['status'];
      final msg = resData['message']?.toString();
      if (status == 0 ||
          status == false ||
          response.statusCode == 400 ||
          response.statusCode == 422) {
        String errorMsg = msg ?? 'فشل إنشاء الحساب، يرجى المحاولة لاحقاً';
        if (resData['errors'] is Map) {
          final errMap = resData['errors'] as Map;
          final first = errMap.values.firstOrNull;
          if (first is List && first.isNotEmpty) {
            errorMsg = first.first.toString();
          }
        }
        throw ServerFailure(errorMsg, response.statusCode);
      }
    }
    return UserModel.fromJson(resData is Map<String, dynamic> ? resData : {});
  }

  @override
  Future<UserModel> getProfile() async {
    // Try /user first, then /auth/me
    try {
      final response = await _dio.get(ApiEndpoints.currentUser);
      final data = response.data;
      if (data is Map<String, dynamic> &&
          (data['status'] == 1 ||
              data['status'] == true ||
              data['data'] != null ||
              data['user'] != null)) {
        return UserModel.fromJson(data);
      }
    } catch (_) {}

    final response = await _dio.get(ApiEndpoints.me);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    return UserModel.fromJson({});
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.updateProfile, data: data);
    ApiResponseHandler.ensureSuccess(
        response.data, 'فشل تحديث بيانات الملف الشخصي');
  }

  @override
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final response = await _dio.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
    ApiResponseHandler.ensureSuccess(response.data, 'فشل تغيير كلمة المرور');
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {}
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await _dio.delete(ApiEndpoints.deleteAccount);
      _checkDeleteStatus(response.data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode != 405 && statusCode != 404) rethrow;
      final response = await _dio.post(ApiEndpoints.deleteAccount);
      _checkDeleteStatus(response.data);
    }
  }

  void _checkDeleteStatus(dynamic data) {
    if (data is Map<String, dynamic>) {
      final status = data['status'];
      final msg = data['message']?.toString();
      if (status == 0 || status == false) {
        throw ServerFailure(msg ?? 'فشل حذف الحساب، يرجى المحاولة لاحقاً');
      }
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    final response = await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final status = data['status'];
      final msg = data['message']?.toString();
      if (status == 0 || status == false) {
        throw ServerFailure(msg ?? 'فشل إرسال رابط استعادة كلمة المرور');
      }
    }
  }

  @override
  Future<String> resendVerificationEmail(String email) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resendVerification,
        data: {'email': email},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      dynamic resData = response.data;
      if (resData is String) {
        try {
          resData = jsonDecode(resData);
        } catch (_) {}
      }
      if (resData is Map<String, dynamic>) {
        final msg = resData['message']?.toString();
        if (resData['status'] == 0 || resData['status'] == false) {
          throw ServerFailure(msg ?? 'فشل إرسال رابط التحقق');
        }
        return msg ?? 'تم إرسال رابط التحقق بنجاح';
      }
      return 'تم إرسال رابط التحقق بنجاح';
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
});
