// Member history tests: loading, loaded, empty and recoverable server error states.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/booking_api.dart';
import 'package:frontend/screens/member_bookings_dialog.dart';
import 'package:frontend/theme/app_theme.dart';

import 'fixtures.dart';

Widget history(BookingApi api) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(
    body: MemberBookingsDialog(memberId: 1, memberName: 'Dana Ali', api: api),
  ),
);
void main() {
  testWidgets('Member history displays status cost and resource', (
    tester,
  ) async {
    await tester.pumpWidget(history(BookingApi(client: fixtureClient())));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('80.00'), findsNWidgets(2));
    expect(find.text('Meeting Room A'), findsNWidgets(2));
  });
  testWidgets('History shows loading then empty', (tester) async {
    final response = Completer<http.Response>();
    await tester.pumpWidget(
      history(BookingApi(client: MockClient((_) => response.future))),
    );
    await tester.pump();
    expect(find.text('Loading booking history...'), findsOneWidget);
    response.complete(jsonResponse([]));
    await tester.pumpAndSettle();
    expect(find.text('No bookings for this member.'), findsOneWidget);
  });
  testWidgets('History displays backend message and Retry recovers', (
    tester,
  ) async {
    int calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) {
        return jsonResponse({
          'message': 'History temporarily unavailable',
        }, 500);
      }
      return jsonResponse([bookingJson()]);
    });
    await tester.pumpWidget(history(BookingApi(client: client)));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('History temporarily unavailable'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed'), findsOneWidget);
  });
}
