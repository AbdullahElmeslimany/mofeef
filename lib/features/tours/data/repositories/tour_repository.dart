import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../models/tour_model.dart';

abstract class TourRepository {
  Future<List<TourModel>> searchTours({
    String? search,
    int? locationId,
    int? categoryId,
    String? priceRange,
    int page = 1,
  });
  Future<TourModel> getTourDetail(dynamic id);
  Future<Map<String, dynamic>> getTourAvailability(dynamic id, {required String start, required String end});
}

class TourRepositoryImpl implements TourRepository {
  final Dio _dio;

  TourRepositoryImpl(this._dio);

  @override
  Future<List<TourModel>> searchTours({
    String? search,
    int? locationId,
    int? categoryId,
    String? priceRange,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tourSearch,
        queryParameters: {
          if (search != null && search.isNotEmpty) 's': search,
          if (locationId != null) 'location_id': locationId,
          if (categoryId != null) 'cat_id': categoryId,
          if (priceRange != null) 'price_range': priceRange,
          'page': page,
          'limit': 10,
        },
      );
      final list = ApiResponseHandler.extractList(response.data);
      return list.map((e) => TourModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<TourModel> getTourDetail(dynamic id) async {
    try {
      final response = await _dio.get(ApiEndpoints.tourDetail(id));
      final data = ApiResponseHandler.getDataOrThrow(response.data, 'لم يتم العثور على التجربة');
      return TourModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getTourAvailability(dynamic id, {required String start, required String end}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tourAvailability(id),
        queryParameters: {'start': start, 'end': end},
      );
      return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {};
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }
}

final tourRepositoryProvider = Provider<TourRepository>((ref) {
  return TourRepositoryImpl(ref.watch(dioProvider));
});

final toursListProvider = FutureProvider.family<List<TourModel>, String?>((ref, search) async {
  return ref.watch(tourRepositoryProvider).searchTours(search: search);
});
