// Desktop UI tests: management state, search, validation, keyboard and responsive layouts.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:frontend/screens/dashboard.dart';
import 'package:frontend/screens/resources.dart';
import 'package:frontend/screens/members.dart';
import 'package:frontend/screens/member_editor_dialog.dart';
import 'package:frontend/screens/resource_editor_dialog.dart';
import 'package:frontend/models/resource.dart';
import 'package:frontend/services/resource_api.dart';
import 'package:frontend/services/member_api.dart';
import 'package:frontend/services/booking_api.dart';
import 'package:frontend/theme/app_theme.dart';

import 'fixtures.dart';

Widget app(Widget child, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: child),
  ),
);
void main() {
  testWidgets('Dashboard navigation uses all six destinations', (tester) async {
    await tester.pumpWidget(app(const Dashboard()));
    await tester.pumpAndSettle();
    for (final destination in [
      'Dashboard',
      'Resources',
      'Members',
      'Availability',
      'New Booking',
      'Bookings',
    ]) {
      expect(find.byTooltip(destination), findsOneWidget);
    }
    expect(find.text('Welcome to CoWorkHub'), findsOneWidget);
  });
  testWidgets('Resources search and combined filters change the loaded list', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(Resources(api: ResourceApi(client: fixtureClient()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Meeting Room A'), findsOneWidget);
    expect(find.text('Desk 1'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, ' ROOM ');
    await tester.pumpAndSettle();
    expect(find.text('Meeting Room A'), findsOneWidget);
    expect(find.text('Desk 1'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No matching resources'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Desk 1'), findsOneWidget);
  });
  testWidgets('Resource error retries and empty state offers Add resource', (
    tester,
  ) async {
    int calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) {
        return jsonResponse({'message': 'Backend unavailable'}, 503);
      }
      return jsonResponse([]);
    });
    await tester.pumpWidget(app(Resources(api: ResourceApi(client: client))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Backend unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No resources yet'), findsOneWidget);
  });
  testWidgets('Member form validates email then Enter saves typed model', (
    tester,
  ) async {
    String? email;
    await tester.pumpWidget(
      app(
        MemberEditor(
          onSave: (draft) async {
            email = draft.email;
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Dana Ali');
    await tester.enterText(find.byType(TextFormField).at(1), 'bad');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a valid email address'), findsOneWidget);
    expect(email, isNull);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'dana@example.com',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(email, 'dana@example.com');
  });
  testWidgets(
    'Pending save prevents duplicate requests and preserves fields on failure',
    (tester) async {
      final result = Completer<void>();
      int calls = 0;
      await tester.pumpWidget(
        app(
          MemberEditor(
            onSave: (_) {
              calls++;
              return result.future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Dana');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'dana@example.com',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(calls, 1);
      result.completeError(Exception('HTTP 409: Email already exists'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email already exists'), findsOneWidget);
      expect(find.text('dana@example.com'), findsOneWidget);
    },
  );
  testWidgets('Members load and search by name', (tester) async {
    final client = fixtureClient();
    await tester.pumpWidget(
      app(
        Members(
          api: MemberApi(client: client),
          bookingApi: BookingApi(client: client),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dana Ali'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'nobody');
    await tester.pumpAndSettle();
    expect(find.text('No matching members'), findsOneWidget);
  });
  testWidgets(
    'Large text and compact window keep resource controls scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(720, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(Resources(api: ResourceApi(client: fixtureClient())), scale: 1.8),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Desk 1'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Resource editor saves a typed room with its subtype fields', (
    tester,
  ) async {
    Resource? saved;
    await tester.pumpWidget(
      app(
        ResourceEditor(
          onSave: (draft) async {
            saved = draft;
          },
        ),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Room Test');
    await tester.enterText(fields.at(1), 'Floor 1');
    await tester.enterText(fields.at(2), '6');
    await tester.enterText(fields.at(3), '80.50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, isA<MeetingRoom>());
    expect(saved!.hourlyRate, 80.50);
    expect(saved!.toJson(), contains('projector'));
  });
}
