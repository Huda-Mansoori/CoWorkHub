import '../models/booking.dart';

// Shared with the existing management forms for the lifetime of the dashboard.
class DemoCatalog {
  final bookings = <Booking>[];
  int nextBookingId = 1;
  int nextMemberId = 2;
  int nextResourceId = 3;
  final members = <Map<String, String>>[
    {'id': '1', 'name': 'Dana Ali', 'email': 'dana@example.com'},
  ];
  final resources = <Map<String, dynamic>>[
    {
      'id': 1,
      'name': 'Meeting Room A',
      'location': 'Floor 1',
      'capacity': 6,
      'hourlyRate': 80.0,
      'status': 'ACTIVE',
      'projector': true,
      'videoConference': false,
    },
    {
      'id': 2,
      'name': 'Desk 1',
      'location': 'Floor 2',
      'capacity': 1,
      'hourlyRate': 20.0,
      'status': 'ACTIVE',
      'deskType': 'Regular Desk',
    },
  ];
}
