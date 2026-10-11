enum Environment { dev, staging, prod }

class AppConfig {
  AppConfig._();

  static Environment currentEnvironment = Environment.staging;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'https://staging.modeef-e.com/api';
      case Environment.staging:
        return 'https://staging.modeef-e.com/api';
      case Environment.prod:
        return 'https://staging.modeef-e.com/api';
    }
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Moyasar API key used by the SDK (Basic auth for /v1/payments).
  /// Supply it at build/run time via --dart-define:
  /// `flutter run --dart-define=MOYASAR_API_KEY=sk_test_xxxxxxxxxxxxx`
  static const String moyasarApiKey =
      'sk_test_45R5KUtbjDaHJrmBemmqhjLcmySFzXygqzwBZBYW';
}
