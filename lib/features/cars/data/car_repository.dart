import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../../../../core/utils/html_utils.dart';

class CarFeatureItem {
  final int id;
  final String title;
  final String? iconUrl;

  const CarFeatureItem({required this.id, required this.title, this.iconUrl});

  factory CarFeatureItem.fromJson(Map<String, dynamic> json) {
    return CarFeatureItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      iconUrl: json['image_id']?.toString() ?? json['icon']?.toString(),
    );
  }
}

class CarModel {
  final String id;
  final String title;
  final String category;
  final double price;
  final double? salePrice;
  final String pricePerDay;
  final int passengerCount;
  final int doors;
  final int baggage;
  final String transmission;
  final String imageUrl;
  final List<String> gallery;
  final String? locationName;
  final double rating;
  final int reviewsCount;
  final String description;
  final List<CarFeatureItem> features;

  const CarModel({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    this.salePrice,
    required this.pricePerDay,
    required this.passengerCount,
    this.doors = 4,
    this.baggage = 3,
    required this.transmission,
    required this.imageUrl,
    this.gallery = const [],
    this.locationName,
    this.rating = 4.8,
    this.reviewsCount = 12,
    this.description = '',
    this.features = const [],
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = double.tryParse(json['price']?.toString() ?? '300') ?? 300.0;
    final rawSalePrice = json['sale_price'] != null && json['sale_price'] != 0
        ? double.tryParse(json['sale_price'].toString())
        : null;

    final effectivePrice = (rawSalePrice != null && rawSalePrice > 0) ? rawSalePrice : rawPrice;

    double parsedRating = 4.8;
    int parsedReviews = 12;
    if (json['review_score'] is Map) {
      parsedRating = double.tryParse(json['review_score']['score_total']?.toString() ?? '4.8') ?? 4.8;
      parsedReviews = int.tryParse(json['review_score']['total_review']?.toString() ?? '12') ?? 12;
      if (parsedRating == 0) parsedRating = 4.8;
    }

    String img = json['image_url']?.toString() ?? json['image']?.toString() ?? '';
    if (img.isEmpty || img.contains('127.0.0.1')) {
      img = 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&q=80';
    }

    List<String> gal = [];
    if (json['gallery'] is List) {
      gal = (json['gallery'] as List)
          .map((e) => e is Map ? (e['large']?.toString() ?? e['thumb']?.toString()) : e.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (gal.isEmpty && img.isNotEmpty) {
      gal = [img];
    }

    List<CarFeatureItem> featList = [];
    if (json['terms'] is Map) {
      final terms = json['terms'] as Map<String, dynamic>;
      for (final val in terms.values) {
        if (val is Map && val['child'] is List) {
          for (final item in (val['child'] as List)) {
            if (item is Map<String, dynamic>) {
              featList.add(CarFeatureItem.fromJson(item));
            }
          }
        }
      }
    }

    String loc = 'الرياض';
    if (json['location'] is Map) {
      loc = json['location']['name']?.toString() ?? 'الرياض';
    } else if (json['location'] != null && json['location'].toString().isNotEmpty) {
      loc = json['location'].toString();
    }

    final rawDesc = json['content']?.toString() ?? json['desc']?.toString() ?? '';
    final cleanDesc = HtmlUtils.stripHtml(rawDesc);

    return CarModel(
      id: json['id']?.toString() ?? '0',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'سيارة فاخرة',
      category: json['category'] is Map ? json['category']['name']?.toString() ?? 'فاخرة' : (json['category']?.toString() ?? 'فاخرة'),
      price: rawPrice,
      salePrice: rawSalePrice,
      pricePerDay: '${effectivePrice.toStringAsFixed(0)} ﷼ / يوم',
      passengerCount: int.tryParse(json['passenger']?.toString() ?? '5') ?? 5,
      doors: int.tryParse(json['door']?.toString() ?? '4') ?? 4,
      baggage: int.tryParse(json['baggage']?.toString() ?? '3') ?? 3,
      transmission: json['gear']?.toString() == 'Auto' ? 'أوتوماتيك' : (json['gear']?.toString() ?? 'أوتوماتيك'),
      imageUrl: img,
      gallery: gal,
      locationName: loc,
      rating: parsedRating,
      reviewsCount: parsedReviews,
      description: cleanDesc.isNotEmpty ? cleanDesc : 'سيارة حديثة ومريحة مجهزة بأعلى معايير السلامة والرفاهية لتنقلاتك داخل المملكة.',
      features: featList,
    );
  }
}

abstract class CarRepository {
  Future<List<CarModel>> searchCars({String? search, int page = 1});
  Future<CarModel> getCarDetail(dynamic id);
}

class CarRepositoryImpl implements CarRepository {
  final Dio _dio;

  CarRepositoryImpl(this._dio);

  @override
  Future<List<CarModel>> searchCars({String? search, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.carSearch,
        queryParameters: {
          if (search != null && search.isNotEmpty) 's': search,
          'page': page,
          'limit': 10,
        },
      );
      final list = ApiResponseHandler.extractList(response.data);
      return list.map((e) => CarModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<CarModel> getCarDetail(dynamic id) async {
    try {
      final response = await _dio.get(ApiEndpoints.carDetail(id));
      final map = ApiResponseHandler.getDataOrThrow(response.data, 'لم يتم العثور على بيانات السيارة');
      return CarModel.fromJson(map as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }
}

final carRepositoryProvider = Provider<CarRepository>((ref) {
  return CarRepositoryImpl(ref.watch(dioProvider));
});

final carsListProvider = FutureProvider<List<CarModel>>((ref) async {
  return ref.watch(carRepositoryProvider).searchCars();
});

final carDetailProvider = FutureProvider.family<CarModel, dynamic>((ref, id) async {
  return ref.watch(carRepositoryProvider).getCarDetail(id);
});


