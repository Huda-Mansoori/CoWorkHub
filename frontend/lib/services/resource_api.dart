import 'dart:convert';


import 'package:http/http.dart' as http;

class ResourceApi {
  // 1- Backend Address
  final String baseUrl = 'http://localhost:8080/api/resources';

  // 2- Get all resources
  Future<List<dynamic>> getResources() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load resources');
    }
  }

  // 3- Add a meeting room
  Future<void> addMeetingRoom(Map<String, dynamic> room) async {
    final response = await http.post(
      Uri.parse(('$baseUrl/rooms')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(room),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add meeting room: ${response.body}');
    }
  }

  // 4- Add desk
  Future<void> addDesk(Map<String, dynamic> desk) async {
    final response = await http.post(
      Uri.parse('$baseUrl/desks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(desk),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add desk: ${response.body}');
    }
  }

  // 5- Update a meeting room
  Future<void> updateMeetingRoom(int id, Map<String, dynamic> room) async {
    final response = await http.put(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(room),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update meeting room: ${response.body}');
    }
  }

  // 6. UPDATE A DESK
  Future<void> updateDesk(int id, Map<String, dynamic> desk) async {
    final response = await http.put(
      Uri.parse('$baseUrl/desks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(desk),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update desk: ${response.body}');
    }
  }

  // 7. DELETE A RESOURCE
  Future<void> deleteResource(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete resource: ${response.body}');
    }
  }
}
