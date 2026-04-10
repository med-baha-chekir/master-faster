import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get baseUrl {
  final envUrl = dotenv.env['BACKEND_URL'];
  if (envUrl != null && envUrl.isNotEmpty) {
    return envUrl;
  }
  // Platform-specific localhost fallback
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}
