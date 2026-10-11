import 'dart:convert';
import 'package:dio/dio.dart';

abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.statusCode]);

  factory ServerFailure.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure('انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        dynamic data = error.response?.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        String message = 'حدث خطأ في الخادم ($statusCode)';
        if (data is Map) {
          final code = data['code']?.toString();
          final rawMsg = (data['message'] ?? data['error'])?.toString();

          if (code == 'invalid_credentials' ||
              rawMsg == 'Password is not correct' ||
              (rawMsg != null && rawMsg.toLowerCase().contains('password is not correct'))) {
            message = 'كلمة المرور أو البريد الإلكتروني غير صحيح';
          } else if (code == 'email_not_verified' ||
              (rawMsg != null && rawMsg.contains('email_not_verified'))) {
            message = (rawMsg != null && rawMsg.isNotEmpty)
                ? rawMsg
                : 'يرجى التحقق من بريدك الإلكتروني قبل تسجيل الدخول.';
          } else if (code == 'account_not_allowed' ||
              (rawMsg != null && rawMsg.contains("account type isn't supported"))) {
            message = 'هذا الحساب مخصص للإدارة أو المرشدين ولا يمكن استخدامه في تطبيق المسافرين';
          } else if (data['errors'] is Map) {
            final errMap = data['errors'] as Map;
            final firstVal = errMap.values.firstOrNull;
            if (firstVal is List && firstVal.isNotEmpty) {
              message = firstVal.first.toString();
            } else if (firstVal != null) {
              message = firstVal.toString();
            }
          } else if (rawMsg != null && rawMsg.isNotEmpty) {
            message = rawMsg;
          }
        }
        return ServerFailure(message, statusCode);
      case DioExceptionType.cancel:
        return const ServerFailure('تم إلغاء الطلب.');
      case DioExceptionType.badCertificate:
        return const ServerFailure('خطأ في شهادة أمان الخادم (SSL)، يرجى التحقق من إعدادات الاتصال.');
      case DioExceptionType.connectionError:
        return const ServerFailure('تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.');
      default:
        final errStr = '${error.error} ${error.message}';
        if (errStr.contains('CERTIFICATE_VERIFY_FAILED') ||
            errStr.contains('HandshakeException') ||
            errStr.contains('Hostname mismatch')) {
          return const ServerFailure('خطأ في شهادة أمان الخادم (SSL Hostname mismatch).');
        }
        dynamic data = error.response?.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map) {
          final code = data['code']?.toString();
          final rawMsg = (data['message'] ?? data['error'])?.toString();
          if (code == 'invalid_credentials' ||
              rawMsg == 'Password is not correct' ||
              (rawMsg != null && rawMsg.toLowerCase().contains('password is not correct'))) {
            return const ServerFailure('كلمة المرور أو البريد الإلكتروني غير صحيح');
          }
          if (rawMsg != null && rawMsg.isNotEmpty) {
            return ServerFailure(rawMsg);
          }
        }
        return const ServerFailure('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.');
    }
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً']);
}
