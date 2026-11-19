import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/screens/member_bookings_dialog.dart';
import 'package:frontend/services/booking_api.dart';

void main() {
  Future<void> open(WidgetTester tester, http.Client client) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: MemberBookingsDialog(
          memberId: 7,
          memberName: 'Dana Ali',
          api: BookingApi('http://localhost/api', client),
        ),
      ),
    );
  }

  testWidgets('Member endpoint displays confirmed and cancelled history', (
    tester,
  ) async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/bookings/member/7');
      return http.Response(
        jsonEncode([
          for (final status in ['CONFIRMED', 'CANCELLED'])
            {
              'id': status == 'CONFIRMED' ? 1 : 2,
              'member': {'id': 7},
              'resource': {'id': 3, 'name': 'Meeting Room A'},
              'startDateTime': '2026-11-18T09:00:00',
              'endDateTime': '2026-11-18T11:00:00',
              'attendees': 4,
              'status': status,
              'totalCost': 160,
            },
        ]),
        200,
      );
    });
    await open(tester, client);
    await tester.pumpAndSettle();
    expect(find.text('Bookings for Dana Ali'), findsOneWidget);
    expect(find.text('Meeting Room A'), findsNWidgets(2));
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('160.00'), findsNWidgets(2));
    expect(find.text('18 Nov 2026 09:00\n18 Nov 2026 11:00'), findsNWidgets(2));
  });

  testWidgets('History shows loading then empty state', (tester) async {
    final response = Completer<http.Response>();
    await open(tester, MockClient((_) => response.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(http.Response('[]', 200));
    await tester.pumpAndSettle();
    expect(find.text('No bookings for this member.'), findsOneWidget);
  });

  testWidgets('History shows server error and retry succeeds', (tester) async {
    var calls = 0;
    await open(
      tester,
      MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('{"message":"Member not found"}', 404)
            : http.Response('[]', 200);
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('HTTP 404: Member not found'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('No bookings for this member.'), findsOneWidget);
  });
}
