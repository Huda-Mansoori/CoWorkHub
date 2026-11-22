// HTTP error handling: preserve the backend message for display by the page.
import 'dart:convert';

import 'package:http/http.dart' as http;

Exception httpError(http.Response response) {
  String message = response.reasonPhrase ?? 'Request failed';
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
  } on FormatException {
    if (response.body.trim().isNotEmpty) message = response.body.trim();
  }
  return Exception('HTTP ${response.statusCode}: $message');
}
