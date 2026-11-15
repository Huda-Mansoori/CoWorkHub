import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Available resource can be booked, cancelled and booked again', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyApp());
    Future<void> tap(String label) async {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
    }

    await tap('Availability');
    await tap('Check availability');
    await tap('Book');
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tap('Dana Ali');
    await tap('Save booking');
    expect(find.text('CONFIRMED'), findsOneWidget);
    await tap('Availability');
    await tap('Check availability');
    expect(find.text('Meeting Room A'), findsNothing);
    await tap('Bookings');
    await tester.ensureVisible(find.byTooltip('Cancel booking'));
    await tester.tap(find.byTooltip('Cancel booking'));
    await tester.pumpAndSettle();
    await tap('Cancel booking');
    expect(find.text('CANCELLED'), findsOneWidget);
    await tap('Availability');
    await tap('Check availability');
    expect(find.text('Meeting Room A'), findsOneWidget);
  });
  testWidgets('Validation shows plain messages and explains desk capacity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('New Booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save booking'));
    await tester.pumpAndSettle();
    expect(find.text('Select a member and a resource.'), findsOneWidget);
    expect(find.textContaining('Format'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dana Ali').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desk 1').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Save booking'));
    await tester.pumpAndSettle();
    expect(
      find.text('A desk can only accommodate 1 attendee.'),
      findsOneWidget,
    );
    expect(find.textContaining('Format'), findsNothing);
  });
}
