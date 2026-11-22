// MemberApi: explicit HTTP methods and JSON mapping for members.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/member.dart';
import 'api_config.dart';
import 'http_error.dart';

class MemberApi {
  final http.Client client;
  final bool _ownsClient;
  MemberApi({http.Client? client})
    : client = client ?? http.Client(),
      _ownsClient = client == null;

  // TRACE: page -> MemberApi.fetchAll -> GET /api/members
  // -> MemberController.getAllMembers -> MemberService -> MemberRepository.findAll -> MySQL
  // <- 200 JSON -> Member.fromJson -> page setState -> list rebuilds.
  Future<List<Member>> fetchAll() async {
    final uri = Uri.parse('$apiBaseUrl/members');
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Member.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // TRACE: page -> MemberApi.create -> POST /api/members
  // -> MemberController.createMember -> MemberService.createMember
  // -> MemberRepository.save -> MySQL <- 201 JSON -> Member.fromJson -> page reload.
  Future<Member> create(Member draft) async {
    final uri = Uri.parse('$apiBaseUrl/members');
    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 201) throw httpError(response);
    return Member.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // TRACE: page -> MemberApi.update -> PUT /api/members/{id}
  // -> MemberController.updateMember -> MemberService.updateMember
  // -> MemberRepository.save -> MySQL <- 200 JSON -> Member.fromJson -> page reload.
  Future<Member> update(int id, Member draft) async {
    final uri = Uri.parse('$apiBaseUrl/members/$id');
    final response = await client
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    return Member.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // TRACE: page -> MemberApi.delete -> DELETE /api/members/{id}
  // -> MemberController.deleteMember -> MemberService.deleteMember
  // -> MemberRepository.delete -> MySQL <- 204 -> page reload; booking history gives 409.
  Future<void> delete(int id) async {
    final uri = Uri.parse('$apiBaseUrl/members/$id');
    final response = await client
        .delete(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 204) throw httpError(response);
    // A successful 204 has no JSON body to decode.
  }

  void close() {
    if (_ownsClient) client.close();
  }
}
