import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(Map<String, dynamic> data);
  Future<UserModel> getProfile();
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> logout();
  Future<void> deleteAccount();
  Future<void> forgotPassword(String email);
  Future<String?> getSavedToken();
  Future<UserModel?> getSavedUser();
  Future<void> saveUser(UserModel user);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final Ref _ref;

  AuthRepositoryImpl(this._remoteDataSource, this._ref);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final user = await _remoteDataSource.login(email, password);
      final storage = _ref.read(secureStorageProvider);
      if (user.token != null && user.token!.isNotEmpty) {
        await storage.write(key: 'auth_token', value: user.token!);
      }
      await storage.write(key: 'user_profile', value: user.toJsonString());
      return user;
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) async {
    try {
      final user = await _remoteDataSource.register(data);
      final storage = _ref.read(secureStorageProvider);
      if (user.token != null && user.token!.isNotEmpty) {
        await storage.write(key: 'auth_token', value: user.token!);
      }
      await storage.write(key: 'user_profile', value: user.toJsonString());
      return user;
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final token = await getSavedToken();
      final profile = await _remoteDataSource.getProfile();
      final userWithToken = UserModel(
        id: profile.id,
        name: profile.name,
        firstName: profile.firstName,
        lastName: profile.lastName,
        email: profile.email,
        phone: profile.phone,
        avatarUrl: profile.avatarUrl,
        role: profile.role,
        token: profile.token ?? token,
      );
      await saveUser(userWithToken);
      return userWithToken;
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _remoteDataSource.updateProfile(data);
      await getProfile();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _remoteDataSource.changePassword(currentPassword, newPassword);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      final storage = _ref.read(secureStorageProvider);
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_profile');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      final storage = _ref.read(secureStorageProvider);
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_profile');
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<String?> getSavedToken() async {
    final storage = _ref.read(secureStorageProvider);
    return await storage.read(key: 'auth_token');
  }

  @override
  Future<UserModel?> getSavedUser() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final str = await storage.read(key: 'user_profile');
      if (str != null && str.isNotEmpty) {
        return UserModel.fromJsonString(str);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: 'user_profile', value: user.toJsonString());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref,
  );
});
