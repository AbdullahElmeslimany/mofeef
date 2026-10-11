import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';

class MuseumModel {
  final int id;
  final String title;
  final String? content;
  final String? imageUrl;
  final String? bannerUrl;
  final double price;
  final String? workingHours;
  final double rating;
  final int reviewsCount;
  final String? locationName;
  final String? address;
  final double? mapLat;
  final double? mapLng;

  const MuseumModel({
    required this.id,
    required this.title,
    this.content,
    this.imageUrl,
    this.bannerUrl,
    required this.price,
    this.workingHours,
    required this.rating,
    required this.reviewsCount,
    this.locationName,
    this.address,
    this.mapLat,
    this.mapLng,
  });

  String get formattedPrice => price > 0 ? '${price.toStringAsFixed(0)} ﷼' : 'دخول مجاني';
  double get ratingAverage => rating;
  bool get isFree => price <= 0;

  factory MuseumModel.fromJson(Map<String, dynamic> json) {
    double parsedRating = 4.9;
    int parsedReviews = 24;

    if (json['review_score'] is Map) {
      parsedRating = double.tryParse(json['review_score']['score_total']?.toString() ?? '4.9') ?? 4.9;
      parsedReviews = int.tryParse(json['review_score']['total_review']?.toString() ?? '24') ?? 24;
    } else if (json['review_score'] != null) {
      parsedRating = double.tryParse(json['review_score']?.toString() ?? '4.9') ?? 4.9;
    }

    String? img = json['image_url']?.toString() ?? json['image']?.toString();
    if (img == null || img.isEmpty || img.contains('127.0.0.1')) {
      img = 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80';
    }

    return MuseumModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? json['desc']?.toString(),
      imageUrl: img,
      bannerUrl: json['banner_image']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      workingHours: json['working_hours']?.toString() ?? '٩ص — ٩م',
      rating: parsedRating,
      reviewsCount: parsedReviews,
      locationName: json['location'] is Map ? json['location']['name']?.toString() : (json['location']?.toString() ?? 'الرياض'),
      address: json['address']?.toString(),
      mapLat: double.tryParse(json['map_lat']?.toString() ?? json['map_latitude']?.toString() ?? '24.7136'),
      mapLng: double.tryParse(json['map_lng']?.toString() ?? json['map_longitude']?.toString() ?? '46.6753'),
    );
  }
}

abstract class MuseumRepository {
  Future<List<MuseumModel>> searchMuseums({String? search, int? locationId, int page = 1});
  Future<MuseumModel> getMuseumDetail(dynamic id);
}

class MuseumRepositoryImpl implements MuseumRepository {
  final Dio _dio;

  MuseumRepositoryImpl(this._dio);

  @override
  Future<List<MuseumModel>> searchMuseums({String? search, int? locationId, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.museumSearch,
        queryParameters: {
          if (search != null && search.isNotEmpty) 's': search,
          if (locationId != null) 'location_id': locationId,
          'page': page,
          'limit': 10,
        },
      );
      final list = ApiResponseHandler.extractList(response.data);
      return list.map((e) => MuseumModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<MuseumModel> getMuseumDetail(dynamic id) async {
    try {
      final response = await _dio.get(ApiEndpoints.museumDetail(id));
      final data = ApiResponseHandler.getDataOrThrow(response.data, 'لم يتم العثور على بيانات المتحف');
      return MuseumModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }
}

final museumRepositoryProvider = Provider<MuseumRepository>((ref) {
  return MuseumRepositoryImpl(ref.watch(dioProvider));
});

final museumsListProvider = FutureProvider<List<MuseumModel>>((ref) async {
  return ref.watch(museumRepositoryProvider).searchMuseums();
});

final museumDetailProvider = FutureProvider.family<MuseumModel, dynamic>((ref, id) async {
  return ref.watch(museumRepositoryProvider).getMuseumDetail(id);
});


