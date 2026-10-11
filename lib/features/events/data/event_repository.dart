import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../../../../core/utils/html_utils.dart';
import '../../tours/data/models/tour_model.dart';

class EventTicketType {
  final String code;
  final String name;
  final String? nameAr;
  final double price;
  final int maxNumber;

  const EventTicketType({
    required this.code,
    required this.name,
    this.nameAr,
    required this.price,
    this.maxNumber = 10,
  });

  int get max => maxNumber;

  String getDisplayName(bool isAr) {
    if (isAr && nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    return name;
  }

  String? getDisplayDesc(bool isAr) {
    if (code.contains('vip')) return isAr ? 'دخول مميز مع خدمات خاصة ومقاعد كبار الشخصيات' : 'VIP entry with premium seats & hospitality';
    if (code.contains('group')) return isAr ? 'باقة مخصصة للعائلات والمجموعات' : 'Special package for families and groups';
    return null;
  }

  factory EventTicketType.fromJson(Map<String, dynamic> json) {
    return EventTicketType(
      code: json['code']?.toString() ?? 'ticket_standard',
      name: json['name']?.toString() ?? 'تذكرة قياسية',
      nameAr: json['name_ar']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '100') ?? 100.0,
      maxNumber: int.tryParse(json['number']?.toString() ?? '10') ?? 10,
    );
  }
}

class EventItemModel {
  final String id;
  final String title;
  final String location;
  final String? address;
  final double? mapLat;
  final double? mapLng;
  final String date;
  final String price;
  final double priceNumeric;
  final double? salePrice;
  final String imageUrl;
  final String description;
  final String duration;
  final String? startTime;
  final String? endTime;
  final List<String> gallery;
  final List<EventTicketType> ticketTypes;
  final List<ExtraPriceModel> extraPrices;

  const EventItemModel({
    required this.id,
    required this.title,
    required this.location,
    this.address,
    this.mapLat,
    this.mapLng,
    required this.date,
    required this.price,
    required this.priceNumeric,
    this.salePrice,
    required this.imageUrl,
    required this.description,
    this.duration = '٤ ساعات',
    this.startTime,
    this.endTime,
    this.gallery = const [],
    this.ticketTypes = const [],
    this.extraPrices = const [],
  });

  double get priceNum => salePrice ?? priceNumeric;
  String get locationName => location;
  double get rating => 4.8;

  factory EventItemModel.fromJson(Map<String, dynamic> map) {
    final rawPrice = double.tryParse(map['price']?.toString() ?? '150') ?? 150.0;
    final sale = map['sale_price'] != null ? double.tryParse(map['sale_price'].toString()) : null;

    // Gallery
    List<String> gal = [];
    if (map['gallery'] is List) {
      gal = (map['gallery'] as List)
          .whereType<String>()
          .where((e) => e.isNotEmpty && !e.contains('127.0.0.1'))
          .toList();
    }

    String img = map['image_url']?.toString() ?? map['image']?.toString() ?? '';
    if (img.isEmpty || img.contains('127.0.0.1')) {
      img = gal.isNotEmpty ? gal.first : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80';
    }

    // Tickets
    List<EventTicketType> tickets = [];
    if (map['ticket_types'] is List) {
      tickets = (map['ticket_types'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => EventTicketType.fromJson(e))
          .toList();
    }

    // Extras
    List<ExtraPriceModel> extras = [];
    if (map['extra_price'] is List) {
      extras = (map['extra_price'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ExtraPriceModel.fromJson(e))
          .toList();
    }

    return EventItemModel(
      id: map['id']?.toString() ?? '0',
      title: map['title']?.toString() ?? 'فعالية مميزة',
      location: map['location'] is Map ? map['location']['name']?.toString() ?? 'الرياض' : (map['location']?.toString() ?? 'الرياض'),
      address: map['address']?.toString(),
      mapLat: double.tryParse(map['map_lat']?.toString() ?? map['map_latitude']?.toString() ?? '24.7136'),
      mapLng: double.tryParse(map['map_lng']?.toString() ?? map['map_longitude']?.toString() ?? '46.6753'),
      date: map['start_date']?.toString() ?? 'اليوم — طوال الأسبوع',
      price: '${(sale ?? rawPrice).toStringAsFixed(0)} ﷼',
      priceNumeric: rawPrice,
      salePrice: sale,
      imageUrl: img,
      description: HtmlUtils.stripHtml(map['content']?.toString() ?? map['description']?.toString() ?? 'فعالية وموسم ثقافي رائع.'),
      duration: map['duration']?.toString() ?? '٤ ساعات',
      startTime: map['start_time']?.toString() ?? '٥:٠٠ م',
      endTime: map['end_time']?.toString() ?? '١١:٠٠ م',
      gallery: gal,
      ticketTypes: tickets,
      extraPrices: extras,
    );
  }
}

abstract class EventRepository {
  Future<List<EventItemModel>> searchEvents({String? search, int? locationId, int page = 1});
  Future<EventItemModel> getEventDetail(dynamic id);
}

class EventRepositoryImpl implements EventRepository {
  final Dio _dio;

  EventRepositoryImpl(this._dio);

  @override
  Future<List<EventItemModel>> searchEvents({String? search, int? locationId, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.eventSearch,
        queryParameters: {
          if (search != null && search.isNotEmpty) 's': search,
          if (locationId != null) 'location_id': locationId,
          'page': page,
          'limit': 12,
        },
      );
      final list = ApiResponseHandler.extractList(response.data);
      return list.map((e) => EventItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<EventItemModel> getEventDetail(dynamic id) async {
    try {
      final response = await _dio.get(ApiEndpoints.eventDetail(id));
      final map = ApiResponseHandler.getDataOrThrow(response.data, 'لم يتم العثور على بيانات الفعالية');
      return EventItemModel.fromJson(map as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure.fromDioException(e);
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(dioProvider));
});

final eventsListProvider = FutureProvider<List<EventItemModel>>((ref) async {
  return ref.watch(eventRepositoryProvider).searchEvents();
});

final eventDetailProvider = FutureProvider.family<EventItemModel, dynamic>((ref, id) async {
  return ref.watch(eventRepositoryProvider).getEventDetail(id);
});
