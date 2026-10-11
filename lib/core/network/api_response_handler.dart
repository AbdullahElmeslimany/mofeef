import 'dart:convert';
import 'dart:developer';
import '../errors/failure.dart';

/// Universal Handler for Modeefe Backend API Responses:
/// - "status": 1 (or true)  => Success (نجح في جلب البيانات)
/// - "status": 0 (or false) => Business Failure / Problem (فيه مشكلة)
class ApiResponseHandler {
  ApiResponseHandler._();

  /// Returns true if the response status indicates success (1 or true)
  static bool isSuccess(dynamic data) {
    if (data == null) return false;
    final map = _toMap(data);
    if (map == null) return false;
    final status = map['status'];
    return status == 1 || status == true || status == '1';
  }

  /// Returns true if the response status indicates failure (0 or false)
  static bool isFailure(dynamic data) {
    if (data == null) return true;
    final map = _toMap(data);
    if (map == null) return true;
    final status = map['status'];
    return status == 0 || status == false || status == '0';
  }

  /// Extracts the exact error message from the response
  static String extractErrorMessage(dynamic data, [String fallback = 'حدث خطأ في معالجة الطلب']) {
    final map = _toMap(data);
    if (map == null) return fallback;

    final code = map['code']?.toString();

    // Known error codes mapped to clear Arabic messages
    if (code == 'invalid_credentials') {
      return 'كلمة المرور أو البريد الإلكتروني غير صحيح';
    }
    if (code == 'invalid_current_password') {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (code == 'email_not_verified') {
      final msg = map['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) {
        if (msg.contains('before booking')) {
          return 'يرجى تفعيل بريدك الإلكتروني قبل إتمام الحجز.';
        }
        return msg;
      }
      return 'يرجى التحقق من بريدك الإلكتروني قبل المتابعة.';
    }
    if (code == 'account_not_allowed') {
      return 'هذا الحساب مخصص للإدارة أو المرشدين ولا يمكن استخدامه في تطبيق المسافرين';
    }

    // Direct string message
    final msg = map['message'];
    if (msg is String && msg.trim().isNotEmpty) {
      if (msg.contains('Password is not correct')) {
        return 'كلمة المرور غير صحيحة';
      }
      return msg;
    }

    // Nested map message (e.g. {"message": {"email": ["The email has already been taken."]}})
    if (msg is Map) {
      final first = msg.values.firstOrNull;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first != null) return first.toString();
    }

    // Validation errors object (e.g. {"errors": {"phone": ["Invalid phone"]}})
    final errors = map['errors'];
    if (errors is Map) {
      final first = errors.values.firstOrNull;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first != null) return first.toString();
    }

    final error = map['error'];
    if (error is String && error.trim().isNotEmpty) return error;

    return fallback;
  }

  /// Validates status and throws ServerFailure if status == 0 or false
  static void ensureSuccess(dynamic data, [String fallback = 'حدث خطأ في معالجة الطلب']) {
    if (isFailure(data)) {
      final msg = extractErrorMessage(data, fallback);
      log('🔴 [API STATUS 0 FAILURE] Thrown: $msg');
      throw ServerFailure(msg);
    }
  }

  /// Returns the "data" payload if status == 1, or throws ServerFailure if status == 0
  static dynamic getDataOrThrow(dynamic data, [String fallback = 'حدث خطأ في جلب البيانات']) {
    ensureSuccess(data, fallback);
    final map = _toMap(data);
    if (map != null && map.containsKey('data')) {
      return map['data'];
    }
    return data;
  }

  /// Extracts a list safely from diverse responses only if status != 0
  static List<dynamic> extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    final map = _toMap(data);
    if (map == null) return [];

    // If status == 0, there is a failure, return empty list
    final status = map['status'];
    if (status == 0 || status == false || status == '0') {
      log('⚠️ [API STATUS 0] Cannot extract list, server returned status 0: ${map['message'] ?? map['code']}');
      return [];
    }

    if (map['data'] is List) return map['data'] as List;
    if (map['data'] is Map) {
      final nested = map['data'] as Map;
      if (nested['data'] is List) return nested['data'] as List;
      if (nested['rows'] is List) return nested['rows'] as List;
      if (nested['items'] is List) return nested['items'] as List;
      if (nested['bookings'] is List) return nested['bookings'] as List;
      if (nested['orders'] is List) return nested['orders'] as List;
    }
    if (map['rows'] is List) return map['rows'] as List;
    if (map['items'] is List) return map['items'] as List;
    if (map['bookings'] is List) return map['bookings'] as List;
    if (map['orders'] is List) return map['orders'] as List;

    return [];
  }

  static Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}
