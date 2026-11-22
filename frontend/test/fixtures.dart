// Test fixtures: HTTP responses only; application code has no mock-data mode.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final roomJson = <String, dynamic>{
  'id': 2,
  'name': 'Meeting Room A',
  'location': 'Floor 1',
  'capacity': 6,
  'hourlyRate': 80,
  'status': 'ACTIVE',
  'projector': true,
  'videoConference': false,
};
final deskJson = <String, dynamic>{
  'id': 3,
  'name': 'Desk 1',
  'location': 'Floor 2',
  'capacity': 1,
  'hourlyRate': 20.0,
  'status': 'ACTIVE',
  'deskType': 'Standing Desk',
};
final memberJson = <String, dynamic>{
  'id': 1,
  'fullName': 'Dana Ali',
  'email': 'dana@example.com',
};
Map<String, dynamic> bookingJson({int id = 7, String status = 'CONFIRMED'}) => {
  'id': id,
  'member': memberJson,
  'resource': roomJson,
  'attendees': 2,
  'startDateTime': '2026-11-24T09:00:00',
  'endDateTime': '2026-11-24T10:00:00',
  'status': status,
  'totalCost': 80.0,
};
http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);
MockClient fixtureClient() => MockClient((request) async {
  if (request.url.path == '/api/members') return jsonResponse([memberJson]);
  if (request.url.path == '/api/resources' ||
      request.url.path == '/api/resources/available') {
    return jsonResponse([roomJson, deskJson]);
  }
  if (request.method == 'PUT') {
    return jsonResponse(bookingJson(status: 'CANCELLED'));
  }
  return jsonResponse([bookingJson(), bookingJson(id: 8, status: 'CANCELLED')]);
});
