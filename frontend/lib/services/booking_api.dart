import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking.dart';

class BookingApi {
  final String base;
  final http.Client client;
  BookingApi(this.base, this.client);

  Future<dynamic> request(
    String method,
    String path, {
    Json? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${base.replaceFirst(RegExp(r'/$'), '')}/$path')
        .replace(queryParameters: query);
    final request = http.Request(method, uri);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = response.reasonPhrase ?? 'Request failed';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] is String) message = data['message'];
      } on FormatException {
        if (response.body.trim().isNotEmpty) message = response.body.trim();
      }
      throw Exception('HTTP ${response.statusCode}: $message');
    }
    return response.body.trim().isEmpty ? null : jsonDecode(response.body);
  }

  Future<List<T>> list<T>(
    String path,
    T Function(Json) parse, {
    Map<String, String>? query,
  }) async => (await request('GET', path, query: query) as List)
      .cast<Json>()
      .map(parse)
      .toList();
  Future<List<Resource>> resources() => list('resources', Resource.fromJson);
  Future<List<Member>> members() => list('members', Member.fromJson);
  Future<List<Booking>> bookings() => list('bookings', Booking.fromJson);
  Future<List<Resource>> available(DateTime start, DateTime end) => list(
    'resources/available',
    Resource.fromJson,
    query: {
      'startDateTime': start.toIso8601String(),
      'endDateTime': end.toIso8601String(),
    },
  );
  Future<void> save(Reservation slot, {int? id, bool cancel = false}) async {
    await request(
      id == null ? 'POST' : 'PUT',
      id == null ? 'bookings' : 'bookings/$id',
      body: {...slot.toJson(), if (cancel) 'status': 'CANCELLED'},
    );
  }
}
