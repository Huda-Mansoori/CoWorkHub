// BookingApi: explicit HTTP methods and JSON mapping for bookings.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking.dart';
import 'api_config.dart';
import 'http_error.dart';

class BookingApi {
  final http.Client client;
  final bool _ownsClient;
  BookingApi({http.Client? client})
    : client = client ?? http.Client(),
      _ownsClient = client == null;

  // TRACE: page -> BookingApi.fetchAll -> GET /api/bookings
  // -> BookingController.getAllBookings -> BookingService -> BookingRepository.findAll -> MySQL
  // <- 200 JSON -> Booking.fromJson -> page setState -> list rebuilds.
  Future<List<Booking>> fetchAll() async {
    final uri = Uri.parse('$apiBaseUrl/bookings');
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // TRACE: member history -> BookingApi.fetchByMember -> GET /api/bookings/member/{id}
  // -> BookingController.getMemberBookings -> BookingService.getBookingsByMember
  // -> MemberRepository.findById + BookingRepository.findByMemberId -> MySQL
  // <- 200 JSON -> Booking.fromJson -> dialog setState -> history list.
  Future<List<Booking>> fetchByMember(int memberId) async {
    final uri = Uri.parse('$apiBaseUrl/bookings/member/$memberId');
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // TRACE: page -> BookingApi.create -> POST /api/bookings
  // -> BookingController.createBooking -> BookingService.createBooking
  // -> BookingRepository.save -> MySQL <- 201 JSON -> Booking.fromJson -> page reload.
  // BookingService.checkRules rejects overlaps (409) and capacity/time/status failures (400).
  Future<Booking> create(Booking draft) async {
    final uri = Uri.parse('$apiBaseUrl/bookings');
    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 201) throw httpError(response);
    return Booking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // TRACE: page -> BookingApi.update -> PUT /api/bookings/{id}
  // -> BookingController.updateBooking -> BookingService.updateBooking
  // -> BookingRepository.save -> MySQL <- 200 JSON -> Booking.fromJson -> page reload.
  // BookingService.checkRules rejects overlaps (409) and capacity/time/status failures (400).
  Future<Booking> update(int id, Booking draft) async {
    final uri = Uri.parse('$apiBaseUrl/bookings/$id');
    final response = await client
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    return Booking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // TRACE: Bookings -> BookingApi.cancel -> PUT /api/bookings/{id} with CANCELLED
  // -> BookingController.updateBooking -> BookingService.updateBooking
  // -> BookingRepository.save -> MySQL <- 200 JSON -> reload; history is retained.
  Future<Booking> cancel(Booking booking) async {
    final uri = Uri.parse('$apiBaseUrl/bookings/${booking.id}');
    final body = booking.toJson();
    body['status'] = 'CANCELLED';
    final response = await client
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    return Booking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void close() {
    if (_ownsClient) client.close();
  }
}
