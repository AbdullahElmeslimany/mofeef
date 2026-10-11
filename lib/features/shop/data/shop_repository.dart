import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../models/product_model.dart';

abstract class ShopRepository {
  Future<List<ProductModel>> searchProducts({String? search, int? categoryId, int page = 1});
  Future<ProductModel> getProductDetail(dynamic id);
  Future<List<Map<String, dynamic>>> getProductFilters();
}

class ShopRepositoryImpl implements ShopRepository {
  final Dio _dio;

  ShopRepositoryImpl(this._dio);

  @override
  Future<List<ProductModel>> searchProducts({String? search, int? categoryId, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.productSearch,
        queryParameters: {
          if (search != null && search.isNotEmpty) 's': search,
          if (categoryId != null) 'cat_id[]': categoryId,
          'page': page,
          'limit': 12,
        },
      );
      final list = ApiResponseHandler.extractList(response.data);
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<ProductModel> getProductDetail(dynamic id) async {
    try {
      final response = await _dio.get(ApiEndpoints.productDetail(id));
      final data = ApiResponseHandler.getDataOrThrow(response.data, 'لم يتم العثور على بيانات المنتج');
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProductFilters() async {
    try {
      final response = await _dio.get(ApiEndpoints.productFilters);
      final list = ApiResponseHandler.extractList(response.data);
      return list.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepositoryImpl(ref.watch(dioProvider));
});

final productsListProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(shopRepositoryProvider).searchProducts();
});

final productDetailProvider = FutureProvider.family<ProductModel, dynamic>((ref, id) async {
  return ref.watch(shopRepositoryProvider).getProductDetail(id);
});

final productFiltersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(shopRepositoryProvider).getProductFilters();
});
