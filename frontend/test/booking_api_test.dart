import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/models/booking.dart';
import 'package:frontend/services/booking_api.dart';

void main() {
  final start = DateTime(2026, 11, 12, 9);
  final end = start.add(const Duration(hours: 1));
  final slot = Reservation(2, 3, 1, start, end);

  test('Adjacent bookings are allowed and cancelled slots are free', () {
    final booking = Booking(1, slot, 'CONFIRMED', 20);
    expect(booking.conflicts(3, start, end), isTrue);
    expect(
      booking.conflicts(3, end, end.add(const Duration(hours: 1))),
      isFalse,
    );
    expect(Booking(1, slot, 'CANCELLED', 20).conflicts(3, start, end), isFalse);
  });

  test('Creating a booking sends IDs and surfaces a server conflict', () async {
    final api = BookingApi(
      'http://localhost/api',
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/bookings');
        expect(jsonDecode(request.body), slot.toJson());
        return http.Response('{"message":"Time slot unavailable"}', 409);
      }),
    );
    await expectLater(
      api.save(slot),
      throwsA(
        predicate((e) => e.toString().contains('409: Time slot unavailable')),
      ),
    );
  });
  test('Availability uses backend start and end parameter names', () async {
    final api = BookingApi(
      'http://localhost/api',
      MockClient((request) async {
        expect(request.url.path, '/api/resources/available');
        expect(request.url.queryParameters, {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        });
        return http.Response('[]', 200);
      }),
    );
    expect(await api.available(start, end), isEmpty);
  });
}
