import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../presentation/guide_list_screen.dart';

abstract class GuideRepository {
  Future<List<GuideModel>> searchGuides(
      {String? search, int? locationId, int page = 1});
  Future<GuideModel> getGuideDetail(dynamic id);
}

class GuideRepositoryImpl implements GuideRepository {
  final Dio _dio;

  GuideRepositoryImpl(this._dio);

  @override
  Future<List<GuideModel>> searchGuides(
      {String? search, int? locationId, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.guideSearch,
        queryParameters: {
          if (search != null && search.isNotEmpty) 's': search,
          if (locationId != null) 'location_id': locationId,
          'page': page,
          'limit': 100,
        },
      );
      final list = ApiResponseHandler.extractList(response.data);
      return list.map((e) => _mapGuide(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<GuideModel> getGuideDetail(dynamic id) async {
    try {
      final response = await _dio.get(ApiEndpoints.guideDetail(id));
      final map = ApiResponseHandler.getDataOrThrow(
          response.data, 'لم يتم العثور على المرشد');
      return _mapGuide(map as Map<String, dynamic>,
          fallbackId: id.toString(), isDetail: true);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  GuideModel _mapGuide(Map<String, dynamic> map,
      {String? fallbackId, bool isDetail = false}) {
    final rawPrice = map['price_per_hour']?.toString() ??
        map['display_price_per_hour']?.toString() ??
        map['price']?.toString();
    String formattedPrice;
    if (rawPrice != null && rawPrice.isNotEmpty) {
      final clean = rawPrice
          .replaceAll('﷼', '')
          .replaceAll('ر.س', '')
          .replaceAll(r'$', '')
          .trim();
      final numVal = double.tryParse(clean);
      formattedPrice = numVal != null
          ? '${numVal.toStringAsFixed(0)} ﷼ / ساعة'
          : '$clean ﷼ / ساعة';
    } else {
      formattedPrice = '250 ﷼ / ساعة';
    }

    final langList = _mapLanguages(map['languages']);
    final avatar = map['avatar_url']?.toString() ?? map['image']?.toString();
    final chosenAvatar = (avatar != null &&
            avatar.isNotEmpty &&
            !avatar.contains('via.placeholder'))
        ? avatar
        : 'https://staging.modeef-e.com/themes/mytravel/images/guide-default.jpg';

    final idStr =
        map['uuid']?.toString() ?? map['id']?.toString() ?? fallbackId ?? '0';
    final rating = _extractRating(map['review_score']);
    final toursCount = int.tryParse(map['museums_count']?.toString() ??
            map['tours_count']?.toString() ??
            (isDetail ? '0' : '12')) ??
        (isDetail ? 0 : 12);

    return GuideModel(
      id: idStr,
      intId: int.tryParse(map['id']?.toString() ?? ''),
      name: map['name']?.toString() ??
          map['title']?.toString() ??
          'مرشد سياحي معتمد',
      title: map['bio']?.toString() ??
          map['description']?.toString() ??
          map['guide_type']?.toString() ??
          'مرشد سياحي مرخص',
      languages: langList,
      rating: rating,
      toursCount: toursCount,
      hourlyRate: formattedPrice,
      imageUrl: chosenAvatar,
      city: map['city']?.toString(),
      yearStarted: map['year_started_working']?.toString(),
      isAvailable: map['is_available'] == true || map['is_available'] == 1,
      freeConsultation:
          map['free_consultation'] == true || map['free_consultation'] == 1,
      hasDiscount: map['has_discount'] == true || map['has_discount'] == 1,
      museums: (map['museums'] is List)
          ? (map['museums'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      events: (map['events'] is List)
          ? (map['events'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      relatedGuides: (map['related_guides'] is List)
          ? (map['related_guides'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }

  List<String> _mapLanguages(dynamic raw) {
    final langList = <String>[];
    if (raw is List) {
      for (var l in raw) {
        final s = l.toString();
        if (s == 'ar' || s == 'ab') {
          langList.add('العربية');
        } else if (s == 'en') {
          langList.add('English');
        } else if (s == 'fr') {
          langList.add('Français');
        } else if (s.isNotEmpty) {
          langList.add(s);
        }
      }
    }
    if (langList.isEmpty) {
      langList.add('العربية');
    }
    return langList;
  }

  double _extractRating(dynamic raw) {
    if (raw is Map) {
      final v = double.tryParse(raw['score_total']?.toString() ?? '');
      if (v != null && v > 0) return v;
    }
    return double.tryParse(raw?.toString() ?? '') ?? 4.9;
  }
}

final guideRepositoryProvider = Provider<GuideRepository>((ref) {
  return GuideRepositoryImpl(ref.watch(dioProvider));
});

final guidesListProvider = FutureProvider<List<GuideModel>>((ref) async {
  return ref.watch(guideRepositoryProvider).searchGuides();
});

final guideDetailProvider =
    FutureProvider.family<GuideModel, dynamic>((ref, id) async {
  return ref.watch(guideRepositoryProvider).getGuideDetail(id);
});
