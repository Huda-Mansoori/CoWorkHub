// Booking page tests: loaded rendering, validation, save/update and cancellation HTTP paths.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:frontend/models/booking.dart';
import 'package:frontend/models/resource.dart';
import 'package:frontend/screens/bookings.dart';
import 'package:frontend/screens/new_booking.dart';
import 'package:frontend/screens/availability.dart';
import 'package:frontend/services/booking_api.dart';
import 'package:frontend/services/member_api.dart';
import 'package:frontend/services/resource_api.dart';
import 'package:frontend/theme/app_theme.dart';

import 'fixtures.dart';

Widget app(Widget page) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: page),
);
void main() {
  testWidgets(
    'Bookings page shows loaded list with status cost Edit and Cancel',
    (tester) async {
      final client = fixtureClient();
      await tester.pumpWidget(
        app(
          Bookings(
            api: BookingApi(client: client),
            memberApi: MemberApi(client: client),
            onEdit: (_) {},
            onNewBooking: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('80.00 QAR'), findsNWidgets(2));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Bookings cancellation confirms sends PUT and refreshes status', (
    tester,
  ) async {
    bool cancelled = false;
    int fetches = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/members') return jsonResponse([memberJson]);
      if (request.method == 'PUT') {
        expect(jsonDecode(request.body)['status'], 'CANCELLED');
        cancelled = true;
        return jsonResponse(bookingJson(status: 'CANCELLED'));
      }
      fetches++;
      return jsonResponse([
        bookingJson(status: cancelled ? 'CANCELLED' : 'CONFIRMED'),
      ]);
    });
    await tester.pumpWidget(
      app(
        Bookings(
          api: BookingApi(client: client),
          memberApi: MemberApi(client: client),
          onEdit: (_) {},
          onNewBooking: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cancelled, isFalse);
    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
    expect(fetches, 2);
    expect(find.text('Cancelled'), findsOneWidget);
  });
  testWidgets(
    'Editing preserves member sends PUT and shows backend conflict without navigation',
    (tester) async {
      int saves = 0;
      bool finished = false;
      final client = MockClient((request) async {
        if (request.url.path == '/api/members') {
          return jsonResponse([memberJson]);
        }
        if (request.url.path == '/api/resources') {
          return jsonResponse([roomJson, deskJson]);
        }
        saves++;
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/bookings/7');
        expect(jsonDecode(request.body)['memberId'], 1);
        return jsonResponse({
          'message':
              'This resource is already booked for the selected time slot.',
        }, 409);
      });
      await tester.pumpWidget(
        app(
          NewBooking(
            bookingApi: BookingApi(client: client),
            memberApi: MemberApi(client: client),
            resourceApi: ResourceApi(client: client),
            bookingToEdit: Booking.fromJson(bookingJson()),
            onSaved: () {
              finished = true;
            },
            onDiscard: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('The member cannot be changed when editing a booking.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Save booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save booking'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(finished, isFalse);
      expect(find.textContaining('HTTP 409:'), findsOneWidget);
    },
  );
  testWidgets('Desk attendee validation prevents a booking request', (
    tester,
  ) async {
    int saves = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/members') return jsonResponse([memberJson]);
      if (request.url.path == '/api/resources') return jsonResponse([deskJson]);
      saves++;
      return jsonResponse(bookingJson(), 201);
    });
    await tester.pumpWidget(
      app(
        NewBooking(
          bookingApi: BookingApi(client: client),
          memberApi: MemberApi(client: client),
          resourceApi: ResourceApi(client: client),
          initialResource: Resource.fromJson(deskJson),
          initialAttendees: 2,
          onSaved: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save booking'));
    await tester.pumpAndSettle();
    expect(
      find.text('A desk can only accommodate 1 attendee.'),
      findsOneWidget,
    );
    expect(saves, 0);
  });
  testWidgets(
    'Availability loads choices then searches the real HTTP contract',
    (tester) async {
      int searches = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/members') {
          return jsonResponse([memberJson]);
        }
        if (request.url.path == '/api/resources/available') {
          searches++;
          expect(
            request.url.queryParameters.keys,
            containsAll(['start', 'end']),
          );
        }
        return jsonResponse([roomJson, deskJson]);
      });
      await tester.pumpWidget(
        app(
          Availability(
            bookingApi: BookingApi(client: client),
            memberApi: MemberApi(client: client),
            resourceApi: ResourceApi(client: client),
            onBook: (_, _, _, _) {},
            onSaved: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check availability'));
      await tester.pumpAndSettle();
      expect(searches, 1);
      expect(find.text('Meeting Room A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('New booking POST refreshes choices and completes successfully', (
    tester,
  ) async {
    int posts = 0;
    bool finished = false;
    final client = MockClient((request) async {
      if (request.url.path == '/api/members') return jsonResponse([memberJson]);
      if (request.url.path == '/api/resources') return jsonResponse([roomJson]);
      expect(request.method, 'POST');
      expect(request.url.path, '/api/bookings');
      final body = jsonDecode(request.body);
      expect(body['memberId'], 1);
      expect(body['resourceId'], 2);
      expect(body, isNot(contains('totalCost')));
      posts++;
      return jsonResponse(bookingJson(), 201);
    });
    await tester.pumpWidget(
      app(
        NewBooking(
          bookingApi: BookingApi(client: client),
          memberApi: MemberApi(client: client),
          resourceApi: ResourceApi(client: client),
          initialResource: Resource.fromJson(roomJson),
          onSaved: () {
            finished = true;
          },
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dana Ali').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save booking'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(finished, isTrue);
    expect(find.text('Booking saved'), findsOneWidget);
  });
  testWidgets('Invalid time range is rejected before HTTP booking submission', (
    tester,
  ) async {
    final client = fixtureClient();
    await tester.pumpWidget(
      app(
        NewBooking(
          bookingApi: BookingApi(client: client),
          memberApi: MemberApi(client: client),
          resourceApi: ResourceApi(client: client),
          initialStart: DateTime(2026, 11, 24, 11),
          initialEnd: DateTime(2026, 11, 24, 10),
          initialResource: Resource.fromJson(roomJson),
          onSaved: () {},
          onDiscard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save booking'));
    await tester.pumpAndSettle();
    expect(
      find.text('End must be after start. Choose a later end date or time.'),
      findsOneWidget,
    );
  });
}
