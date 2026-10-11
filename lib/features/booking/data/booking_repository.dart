import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_handler.dart';
import '../../auth/auth_provider.dart';

class BookingItemModel {
  final int id;
  final String code;
  final String serviceTitle;
  final String serviceType;
  final String startDate;
  final String? endDate;
  final double total;
  final String status;
  final int totalGuests;
  final String? image;
  final String? location;

  const BookingItemModel({
    required this.id,
    required this.code,
    required this.serviceTitle,
    required this.serviceType,
    required this.startDate,
    this.endDate,
    required this.total,
    required this.status,
    required this.totalGuests,
    this.image,
    this.location,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] is Map
        ? json['service'] as Map<String, dynamic>
        : (json['object'] is Map
            ? json['object'] as Map<String, dynamic>
            : json);

    // Extract title from service, object, or root
    final title = service['title']?.toString() ??
        service['name']?.toString() ??
        json['service_title']?.toString() ??
        json['service_name']?.toString() ??
        json['title']?.toString() ??
        json['order_title']?.toString() ??
        json['name']?.toString() ??
        'حجز رحلة';

    // Extract code
    final code = json['code']?.toString() ??
        json['booking_code']?.toString() ??
        json['order_number']?.toString() ??
        'MDF-${json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Extract total safely
    final rawTotal =
        json['total']?.toString() ?? json['price']?.toString() ?? '0';
    final cleanedTotal = rawTotal.replaceAll(RegExp(r'[^0-9.]'), '');
    final total = double.tryParse(cleanedTotal) ?? 0.0;

    // Extract date
    final date = json['start_date']?.toString() ??
        json['date']?.toString() ??
        json['created_at']?.toString() ??
        '';

    // Extract guests
    final guests = int.tryParse(json['total_guests']?.toString() ??
            json['guests']?.toString() ??
            json['adults']?.toString() ??
            json['number']?.toString() ??
            '1') ??
        1;

    // Extract image
    final image = json['image']?.toString() ??
        json['image_url']?.toString() ??
        service['image']?.toString() ??
        service['image_url']?.toString() ??
        service['feature_image']?.toString() ??
        service['banner_image']?.toString() ??
        json['banner_image']?.toString();

    // Extract location
    final location = json['location']?.toString() ??
        json['address']?.toString() ??
        service['location']?.toString() ??
        service['address']?.toString() ??
        (service['location_map'] is Map
            ? service['location_map']['name']?.toString()
            : null);

    return BookingItemModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: code,
      serviceTitle: title,
      serviceType: json['object_model']?.toString() ??
          json['service_type']?.toString() ??
          'tour',
      startDate: date,
      endDate: json['end_date']?.toString(),
      total: total,
      status: json['status']?.toString() ?? 'confirmed',
      totalGuests: guests,
      image: image,
      location: location,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'service_title': serviceTitle,
        'service_type': serviceType,
        'start_date': startDate,
        'end_date': endDate,
        'total': total,
        'status': status,
        'total_guests': totalGuests,
        'image': image,
        'location': location,
      };
}

class TicketModel {
  final int id;
  final String ticketCode;
  final String bookingCode;
  final String title;
  final String date;
  final String? qrUrl;
  final int totalGuests;
  final double total;
  final String status;
  final String? image;

  const TicketModel({
    required this.id,
    required this.ticketCode,
    required this.bookingCode,
    required this.title,
    required this.date,
    this.qrUrl,
    this.totalGuests = 1,
    this.total = 0.0,
    this.status = 'confirmed',
    this.image,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total']?.toString() ?? '0';
    final cleanedTotal = rawTotal.replaceAll(RegExp(r'[^0-9.]'), '');
    final total = double.tryParse(cleanedTotal) ?? 0.0;

    return TicketModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ticketCode: json['ticket_code']?.toString() ??
          json['code']?.toString() ??
          json['id']?.toString() ??
          '',
      bookingCode:
          json['booking_code']?.toString() ?? json['code']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['service_title']?.toString() ??
          'تذكرة دخول',
      date: json['date']?.toString() ?? json['start_date']?.toString() ?? '',
      qrUrl: json['qr_url']?.toString(),
      totalGuests: int.tryParse(json['total_guests']?.toString() ??
              json['guests']?.toString() ??
              '1') ??
          1,
      total: total,
      status: json['status']?.toString() ?? 'confirmed',
      image: json['image']?.toString() ?? json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_code': ticketCode,
        'booking_code': bookingCode,
        'title': title,
        'date': date,
        'qr_url': qrUrl,
        'total_guests': totalGuests,
        'total': total,
        'status': status,
        'image': image,
      };
}

abstract class BookingRepository {
  Future<Map<String, dynamic>> addToCart({
    required int serviceId,
    required String serviceType,
    required String startDate,
    int? guests,
    Map<String, dynamic>? extraData,
  });
  Future<Map<String, dynamic>> doCheckout(Map<String, dynamic> bookingData);
  Future<List<BookingItemModel>> getBookingHistory({String status = ''});
  Future<List<TicketModel>> getMyTickets();
  Future<void> saveBookingLocally(BookingItemModel booking);
  Future<void> saveTicketLocally(TicketModel ticket);
}

class BookingRepositoryImpl implements BookingRepository {
  final Dio _dio;
  static const String _bookingsStorageKey = 'user_saved_bookings_v2';
  static const String _ticketsStorageKey = 'user_saved_tickets_v2';

  BookingRepositoryImpl(this._dio);

  /// Helper to extract list from diverse Laravel / Bravo CMS response structures
  List<dynamic> _extractList(dynamic data) {
    return ApiResponseHandler.extractList(data);
  }

  @override
  Future<void> saveBookingLocally(BookingItemModel booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_bookingsStorageKey);
      List<dynamic> list = [];
      if (savedString != null && savedString.isNotEmpty) {
        try {
          list = jsonDecode(savedString) as List<dynamic>;
        } catch (_) {}
      }

      list.removeWhere(
          (item) => item['code'] == booking.code || item['id'] == booking.id);
      list.insert(0, booking.toJson());
      await prefs.setString(_bookingsStorageKey, jsonEncode(list));

      // Also create and save corresponding ticket
      final ticket = TicketModel(
        id: booking.id,
        ticketCode: 'TKT-${booking.code.replaceAll('MDF-', '')}',
        bookingCode: booking.code,
        title: booking.serviceTitle,
        date: booking.startDate,
        totalGuests: booking.totalGuests,
        total: booking.total,
        status: booking.status,
        image: booking.image,
      );
      await saveTicketLocally(ticket);
    } catch (_) {}
  }

  @override
  Future<void> saveTicketLocally(TicketModel ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_ticketsStorageKey);
      List<dynamic> list = [];
      if (savedString != null && savedString.isNotEmpty) {
        try {
          list = jsonDecode(savedString) as List<dynamic>;
        } catch (_) {}
      }

      list.removeWhere((item) =>
          item['booking_code'] == ticket.bookingCode ||
          item['ticket_code'] == ticket.ticketCode);
      list.insert(0, ticket.toJson());
      await prefs.setString(_ticketsStorageKey, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> addToCart({
    required int serviceId,
    required String serviceType,
    required String startDate,
    int? guests,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = {
        'service_id': serviceId,
        'service_type': serviceType,
        'start_date': startDate,
        if (guests != null) 'guests': guests,
        ...?extraData,
      };
      log('🛒 [BOOKING] addToCart payload: $payload');
      final response =
          await _dio.post(ApiEndpoints.addToCartBooking, data: payload);
      log('🛒 [BOOKING] addToCart response: ${response.data}');
      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      ApiResponseHandler.ensureSuccess(data, 'فشل إضافة الحجز إلى السلة');
      return data is Map<String, dynamic> ? data : {};
    } on DioException catch (e) {
      log('❌ [BOOKING] addToCart DioException: ${e.response?.data}');
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> doCheckout(
      Map<String, dynamic> bookingData) async {
    try {
      log('💳 [BOOKING] doCheckout payload: $bookingData');
      final response =
          await _dio.post(ApiEndpoints.doCheckout, data: bookingData);
      log('💳 [BOOKING] doCheckout response: ${response.data}');
      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      ApiResponseHandler.ensureSuccess(data, 'فشل إتمام الحجز والدفع');
      return data is Map<String, dynamic> ? data : {};
    } on DioException catch (e) {
      log('❌ [BOOKING] doCheckout DioException: ${e.response?.data}');
      throw ServerFailure.fromDioException(e);
    }
  }

  @override
  Future<List<BookingItemModel>> getBookingHistory({String status = ''}) async {
    // 1. Get locally saved bookings
    List<BookingItemModel> localBookings = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_bookingsStorageKey);
      if (savedString != null && savedString.isNotEmpty) {
        final list = jsonDecode(savedString) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              localBookings.add(BookingItemModel.fromJson(item));
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 2. Fetch from remote API
    List<BookingItemModel> remoteBookings = [];

    // Attempt A: Primary booking history endpoint (/user/booking-history)
    try {
      log('📦 [BOOKING HISTORY] Fetching from ${ApiEndpoints.bookingHistory} (status: "$status")');
      final response = await _dio.get(
        ApiEndpoints.bookingHistory,
        queryParameters: {if (status.isNotEmpty) 'status': status},
      );
      log('📦 [BOOKING HISTORY] Response: ${response.data}');
      final list = _extractList(response.data);
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            remoteBookings.add(BookingItemModel.fromJson(item));
          } catch (e) {
            log('⚠️ [BOOKING HISTORY] Parsing error for item: $e');
          }
        }
      }
      log('📦 [BOOKING HISTORY] Successfully parsed ${remoteBookings.length} bookings');
    } catch (e) {
      log('❌ [BOOKING HISTORY] Primary endpoint error: $e');
    }

    // Attempt B: Fallback endpoint (/user/booking/history) if primary was empty
    if (remoteBookings.isEmpty) {
      try {
        log('📦 [BOOKING HISTORY] Trying fallback endpoint /user/booking/history');
        final response = await _dio.get(ApiEndpoints.bookingHistory);
        final list = _extractList(response.data);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              remoteBookings.add(BookingItemModel.fromJson(item));
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    // Attempt C: Also fetch /my-orders (shop orders) and include them
    try {
      log('🛍️ [MY ORDERS] Fetching shop orders from ${ApiEndpoints.myOrders}');
      final ordersResp = await _dio.get(ApiEndpoints.myOrders);
      final list = _extractList(ordersResp.data);
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            final orderModel = BookingItemModel.fromJson({
              ...item,
              'service_type': item['service_type'] ?? 'order',
              'service_title': item['service_title'] ??
                  item['title'] ??
                  item['order_title'] ??
                  'طلب متجر',
            });
            remoteBookings.add(orderModel);
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 3. Merge both sources (local + remote)
    final Map<String, BookingItemModel> combined = {};
    for (final b in remoteBookings) {
      combined[b.code] = b;
    }
    // Local bookings take top priority if freshly booked
    for (final b in localBookings) {
      combined[b.code] = b;
    }

    var result = combined.values.toList();
    if (status.isNotEmpty) {
      result = result
          .where((b) => b.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return result;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    // 1. Get local tickets
    List<TicketModel> localTickets = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_ticketsStorageKey);
      if (savedString != null && savedString.isNotEmpty) {
        final list = jsonDecode(savedString) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              localTickets.add(TicketModel.fromJson(item));
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 2. Auto-generate ticket for any local booking missing a ticket
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_bookingsStorageKey);
      if (savedString != null && savedString.isNotEmpty) {
        final list = jsonDecode(savedString) as List<dynamic>;
        for (final b in list) {
          if (b is Map<String, dynamic>) {
            try {
              final booking = BookingItemModel.fromJson(b);
              final exists =
                  localTickets.any((t) => t.bookingCode == booking.code);
              if (!exists) {
                localTickets.add(TicketModel(
                  id: booking.id,
                  ticketCode: 'TKT-${booking.code.replaceAll('MDF-', '')}',
                  bookingCode: booking.code,
                  title: booking.serviceTitle,
                  date: booking.startDate,
                  totalGuests: booking.totalGuests,
                  total: booking.total,
                  status: booking.status,
                  image: booking.image,
                ));
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 3. Fetch from remote API (/user/ticket)
    List<TicketModel> remoteTickets = [];
    try {
      log('🎟️ [MY TICKETS] Fetching from ${ApiEndpoints.myTickets}');
      final response = await _dio.get(ApiEndpoints.myTickets);
      log('🎟️ [MY TICKETS] Response: ${response.data}');
      final list = _extractList(response.data);
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            remoteTickets.add(TicketModel.fromJson(item));
          } catch (_) {}
        }
      }
    } catch (e) {
      log('❌ [MY TICKETS] Error: $e');
    }

    final Map<String, TicketModel> combined = {};
    for (final t in remoteTickets) {
      combined[t.bookingCode.isNotEmpty ? t.bookingCode : t.ticketCode] = t;
    }
    for (final t in localTickets) {
      combined[t.bookingCode.isNotEmpty ? t.bookingCode : t.ticketCode] = t;
    }
    return combined.values.toList();
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(dioProvider));
});

final bookingHistoryProvider =
    FutureProvider.family<List<BookingItemModel>, String>((ref, status) async {
  // Re-fetch automatically whenever authentication status changes (login, logout, account switch)!
  ref.watch(authProvider);
  return ref.watch(bookingRepositoryProvider).getBookingHistory(status: status);
});

final myTicketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  // Re-fetch automatically whenever authentication status changes!
  ref.watch(authProvider);
  return ref.watch(bookingRepositoryProvider).getMyTickets();
});
