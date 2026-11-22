// BookingApi tests: HTTP paths, JSON bodies, expected status codes and backend messages.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:frontend/models/booking.dart';
import 'package:frontend/services/booking_api.dart';

import 'fixtures.dart';

void main() {
  test('BookingApi GET decodes a typed list', () async {
    final api = BookingApi(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/bookings');
        return jsonResponse([bookingJson()]);
      }),
    );
    expect(await api.fetchAll(), hasLength(1));
  });
  test('BookingApi create expects 201 and sends request fields', () async {
    final api = BookingApi(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(
          jsonDecode(request.body),
          Booking.fromJson(bookingJson()).toJson(),
        );
        return jsonResponse(bookingJson(), 201);
      }),
    );
    expect((await api.create(Booking.fromJson(bookingJson()))).id, 7);
  });
  test('BookingApi update expects 200', () async {
    final api = BookingApi(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/bookings/7');
        return jsonResponse(bookingJson());
      }),
    );
    await api.update(7, Booking.fromJson(bookingJson()));
  });
  test('BookingApi exposes the backend 409 message', () async {
    final api = BookingApi(
      client: MockClient(
        (_) async => jsonResponse({
          'status': 409,
          'error': 'Conflict',
          'message': 'Already exists or overlaps.',
        }, 409),
      ),
    );
    await expectLater(
      api.create(Booking.fromJson(bookingJson())),
      throwsA(
        predicate(
          (e) => e.toString().contains('HTTP 409: Already exists or overlaps.'),
        ),
      ),
    );
  });
  test('BookingApi rejects an unexpected success status', () async {
    final api = BookingApi(
      client: MockClient((_) async => jsonResponse(bookingJson(), 200)),
    );
    await expectLater(
      api.create(Booking.fromJson(bookingJson())),
      throwsException,
    );
  });
  test('Member history uses the member-specific endpoint', () async {
    final api = BookingApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/bookings/member/1');
        return jsonResponse([bookingJson()]);
      }),
    );
    expect(await api.fetchByMember(1), hasLength(1));
  });
  test('Cancellation sends original booking fields plus CANCELLED', () async {
    final booking = Booking.fromJson(bookingJson());
    final api = BookingApi(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/bookings/7');
        expect(jsonDecode(request.body), {
          ...booking.toJson(),
          'status': 'CANCELLED',
        });
        return jsonResponse(bookingJson(status: 'CANCELLED'));
      }),
    );
    expect((await api.cancel(booking)).status, 'CANCELLED');
  });
}
