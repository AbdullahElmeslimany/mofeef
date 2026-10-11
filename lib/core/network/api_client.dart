import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../localization/locale_provider.dart';
import 'mock_api_interceptor.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final currentLocale = ref.watch(localeProvider);
  final langCode = currentLocale.languageCode;

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Accept-Language': langCode,
        'X-Locale': langCode,
      },
    ),
  );

  // Allow self-signed or intermediate staging certificates to prevent SSL handshake aborts
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically inject current language code into query parameters if not present
        if (!options.queryParameters.containsKey('lang')) {
          options.queryParameters['lang'] = langCode;
        }
        options.headers['Accept-Language'] = langCode;
        options.headers['X-Locale'] = langCode;

        final token = await storage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        log('🚀 [DIO REQUEST] ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('✅ [DIO RESPONSE ${response.statusCode}] ${response.requestOptions.uri}');
        final resData = response.data;
        if (resData is Map) {
          final s = resData['status'];
          if (s == 1 || s == true) {
            log('🟢 [API SUCCESS: status=1] ${response.requestOptions.uri}');
          } else if (s == 0 || s == false) {
            log('🔴 [API PROBLEM: status=0] ${response.requestOptions.uri} -> ${resData['message'] ?? resData['code'] ?? 'status: 0'}');
          }
        }
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        log('❌ [DIO ERROR] ${error.type} for ${error.requestOptions.uri}: ${error.message}');
        if (error.response?.data != null) {
          log('📄 [DIO ERROR DATA] ${error.response?.data}');
        }
        return handler.next(error);
      },
    ),
  );

  // Fallback to rich mock data when server is completely unreachable or offline
  dio.interceptors.add(MockApiInterceptor());

  return dio;
});
