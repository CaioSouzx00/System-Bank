import 'package:flutter/foundation.dart';

class EnvConfig {
  static const String appName = 'System-Bank';
  static const String appVersion = '1.0.0';

  // Default API URL based on platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    // Android emulator routes host localhost via 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Maximum number of retry attempts for failed network requests
  static const int maxRetries = 3;
}
