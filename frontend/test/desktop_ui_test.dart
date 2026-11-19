import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/members.dart';
import 'package:frontend/screens/resources.dart';
import 'package:frontend/services/demo_catalog.dart';
import 'package:frontend/theme/app_theme.dart';

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> setSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('All six screens remain usable in a compact desktop window', (
    tester,
  ) async {
    await setSize(tester, const Size(640, 720));
    await tester.pumpWidget(const MyApp(apiBase: ''));
    await tester.pumpAndSettle();
    for (final label in [
      'Resources',
      'Members',
      'Availability',
      'New Booking',
      'Bookings',
      'Dashboard',
    ]) {
      await tapVisible(tester, find.byTooltip(label));
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets(
    'Resource empty state opens a form with specific inline validation',
    (tester) async {
      await setSize(tester, const Size(900, 800));
      final catalog = DemoCatalog()..resources.clear();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: Resources(catalog, apiBase: '')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No resources yet'), findsOneWidget);
      await tapVisible(tester, find.text('Add resource'));
      await tapVisible(tester, find.text('Save'));
      expect(find.text('This field is required.'), findsWidgets);
      expect(find.text('Enter a capacity of at least 1.'), findsOneWidget);
      expect(catalog.resources, isEmpty);
    },
  );

  testWidgets(
    'Resource search filters cards and clear filters restores results',
    (tester) async {
      await setSize(tester, const Size(1000, 900));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: Resources(DemoCatalog(), apiBase: '')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'unmatched');
      await tester.pumpAndSettle();
      expect(find.text('No matching resources'), findsOneWidget);
      await tapVisible(tester, find.text('Clear filters'));
      expect(find.text('Meeting Room A'), findsOneWidget);
      expect(find.text('Desk 1'), findsOneWidget);
    },
  );

  testWidgets(
    'Control F focuses member search and safe confirmation defaults to cancel',
    (tester) async {
      await setSize(tester, const Size(1000, 850));
      final catalog = DemoCatalog();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: Members(catalog, apiBase: '')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tapVisible(tester, find.byTooltip('Delete member'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(catalog.members, hasLength(1));
      expect(find.text('Delete member?'), findsNothing);
    },
  );

  testWidgets(
    'Member creation validates email and refreshes the list after Enter',
    (tester) async {
      await setSize(tester, const Size(1000, 850));
      final catalog = DemoCatalog();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: Members(catalog, apiBase: '')),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Add member'));
      await tester.enterText(field('Member name *'), 'Leila Ahmed');
      await tester.enterText(field('Email *'), 'invalid');
      await tapVisible(tester, find.text('Save'));
      expect(
        find.text('Enter a valid email address, e.g. dana@example.com.'),
        findsOneWidget,
      );
      await tester.enterText(field('Email *'), 'leila@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(catalog.members, hasLength(2));
      expect(find.text('Leila Ahmed'), findsOneWidget);
    },
  );

  testWidgets(
    'Saving blocks duplicate requests and preserves fields after a server error',
    (tester) async {
      await setSize(tester, const Size(900, 800));
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MemberEditor(
                    onSave: (_, _) {
                      calls++;
                      return pending.future;
                    },
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tapVisible(tester, find.text('Open'));
      await tester.enterText(field('Member name *'), 'Dana Ali');
      await tester.enterText(field('Email *'), 'dana@example.com');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(calls, 1);
      pending.completeError(Exception('This email is already registered.'));
      await tester.pumpAndSettle();
      expect(find.text('This email is already registered.'), findsOneWidget);
      expect(find.text('Dana Ali'), findsOneWidget);
      expect(find.text('dana@example.com'), findsOneWidget);
    },
  );

  testWidgets(
    'Large text and a short window keep resource controls reachable',
    (tester) async {
      await setSize(tester, const Size(720, 500));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(body: Resources(DemoCatalog(), apiBase: '')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Add resource'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Cancel'));
    },
  );
  testWidgets('Search shortcut works while sidebar navigation has focus', (
    tester,
  ) async {
    await setSize(tester, const Size(1440, 900));
    await tester.pumpWidget(const MyApp(apiBase: ''));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Members').first);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode!
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('Failed resource loading provides an error message and Retry', (
    tester,
  ) async {
    await setSize(tester, const Size(1000, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Resources(DemoCatalog(), apiBase: 'http://backend.invalid/api'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load resources.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tapVisible(tester, find.text('Retry'));
    expect(find.text('Could not load resources.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Editing a booking preserves its member and updates the reservation',
    (tester) async {
      await setSize(tester, const Size(1440, 900));
      await tester.pumpWidget(const MyApp(apiBase: ''));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('New Booking'));
      await tapVisible(tester, find.byType(DropdownButtonFormField<int>).first);
      await tapVisible(tester, find.text('Dana Ali').last);
      await tapVisible(tester, find.byType(DropdownButtonFormField<int>).last);
      await tapVisible(tester, find.text('Meeting Room A').last);
      await tapVisible(tester, find.text('Save booking'));
      await tapVisible(tester, find.text('Edit').first);
      expect(
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>).first,
            )
            .onChanged,
        isNull,
      );
      await tester.enterText(find.byType(TextField).first, '3');
      await tapVisible(tester, find.text('Save booking'));
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    },
  );
}
