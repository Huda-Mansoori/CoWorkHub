import 'package:http/http.dart' as http;

import 'booking_api.dart';

class MemberApi {
  final http.Client _client = http.Client();
  late final BookingApi _api = BookingApi(
    const String.fromEnvironment(
      'COWORK_API_BASE',
      defaultValue: 'http://localhost:8080/api',
    ),
    _client,
  );

  Future<List<dynamic>> getMembers() async =>
      await _api.request('GET', 'members') as List;
  Future<void> addMember(String name, String email) async {
    await _api.request(
      'POST',
      'members',
      body: {'fullName': name, 'email': email},
    );
  }

  Future<void> updateMember(String id, String name, String email) async {
    await _api.request(
      'PUT',
      'members/$id',
      body: {'fullName': name, 'email': email},
    );
  }

  Future<void> deleteMember(String id) async {
    await _api.request('DELETE', 'members/$id');
  }

  void close() => _client.close();
}
