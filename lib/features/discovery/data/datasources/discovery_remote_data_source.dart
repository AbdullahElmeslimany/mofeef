import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../models/discovery_models.dart';

abstract class DiscoveryRemoteDataSource {
  Future<List<ServiceCategoryModel>> getServices();
  Future<List<LocationModel>> getLocations({String search = '', int page = 1});
  Future<List<NewsItemModel>> getNews();
  Future<Map<String, dynamic>> getHomeLayout();
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final Dio _dio;

  DiscoveryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ServiceCategoryModel>> getServices() async {
    final response = await _dio.get(ApiEndpoints.services);
    final list = ApiResponseHandler.extractList(response.data);
    return list.map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LocationModel>> getLocations({String search = '', int page = 1}) async {
    final response = await _dio.get(
      ApiEndpoints.locations,
      queryParameters: {'s': search, 'page': page, 'limit': 20},
    );
    final list = ApiResponseHandler.extractList(response.data);
    return list.map((e) => LocationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<NewsItemModel>> getNews() async {
    final response = await _dio.get(ApiEndpoints.news);
    final list = ApiResponseHandler.extractList(response.data);
    return list.map((e) => NewsItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Map<String, dynamic>> getHomeLayout() async {
    final response = await _dio.get(ApiEndpoints.homeLayout);
    final data = response.data;
    if (ApiResponseHandler.isFailure(data)) return {};
    return data is Map<String, dynamic> ? data : {};
  }
}

final discoveryRemoteDataSourceProvider = Provider<DiscoveryRemoteDataSource>((ref) {
  return DiscoveryRemoteDataSourceImpl(ref.watch(dioProvider));
});
