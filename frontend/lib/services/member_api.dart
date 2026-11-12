import 'dart:convert';
import 'package:http/http.dart' as http;

class MemberApi {

  // 1. BACKEND ADDRESS
  final String baseUrl = 'http://localhost:8080/api/members';

  // 2. GET ALL MEMBERS
  Future<List<dynamic>> getMembers() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load members');
    }
  }

  // 3. ADD MEMBER
  Future<void> addMember(String name, String email) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name,
        'email': email,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add member');
    }
  }

  // 4. UPDATE MEMBER
  Future<void> updateMember(
    String id,
    String name,
    String email,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name,
        'email': email,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update member');
    }
  }

  // 5. DELETE MEMBER
  Future<void> deleteMember(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete member');
    }
  }
}