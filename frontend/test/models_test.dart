// Model tests: real response shapes, subtype detection and request-only serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/resource.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/booking.dart';

import 'fixtures.dart';

void main() {
  test('Resource detects room and desk without a type discriminator', () {
    final room = Resource.fromJson(roomJson);
    final desk = Resource.fromJson(deskJson);
    expect(room, isA<MeetingRoom>());
    expect(desk, isA<Desk>());
    expect(room.hourlyRate, 80.0);
    expect((desk as Desk).deskType, 'Standing Desk');
    expect(room.toJson(), isNot(contains('id')));
    expect(room.toJson(), isNot(contains('deskType')));
    expect(desk.toJson(), isNot(contains('projector')));
    expect(desk.capacity, 1);
  });
  test('Member maps fullName and excludes ID from editable JSON', () {
    final member = Member.fromJson(memberJson);
    expect(member.fullName, 'Dana Ali');
    expect(member.toJson(), {
      'fullName': 'Dana Ali',
      'email': 'dana@example.com',
    });
  });
  test('Booking reads nested objects and sends IDs with ISO dates only', () {
    final booking = Booking.fromJson(bookingJson());
    expect(booking.member.id, 1);
    expect(booking.resource.name, 'Meeting Room A');
    expect(booking.totalCost, 80.0);
    expect(booking.toJson(), {
      'memberId': 1,
      'resourceId': 2,
      'attendees': 2,
      'startDateTime': '2026-11-24T09:00:00.000',
      'endDateTime': '2026-11-24T10:00:00.000',
    });
  });
  test('Lazy nested resource common fields are retained without inventing a subtype', () {
    final json = bookingJson();
    final common = Map<String, dynamic>.from(roomJson)
      ..remove('projector')
      ..remove('videoConference');
    json['resource'] = common;
    expect(Booking.fromJson(json).resource.name, 'Meeting Room A');
  });
}
