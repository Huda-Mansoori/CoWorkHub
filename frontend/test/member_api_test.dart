// MemberApi tests: HTTP paths, JSON bodies, expected status codes and backend messages.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/member_api.dart';

import 'fixtures.dart';

void main() {
  test('MemberApi GET decodes a typed list', () async {
    final api = MemberApi(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/members');
        return jsonResponse([memberJson]);
      }),
    );
    expect(await api.fetchAll(), hasLength(1));
  });
  test('MemberApi create expects 201 and sends request fields', () async {
    final api = MemberApi(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), Member.fromJson(memberJson).toJson());
        return jsonResponse(memberJson, 201);
      }),
    );
    expect((await api.create(Member.fromJson(memberJson))).id, 1);
  });
  test('MemberApi update expects 200', () async {
    final api = MemberApi(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/members/7');
        return jsonResponse(memberJson);
      }),
    );
    await api.update(7, Member.fromJson(memberJson));
  });
  test('MemberApi exposes the backend 409 message', () async {
    final api = MemberApi(
      client: MockClient(
        (_) async => jsonResponse({
          'status': 409,
          'error': 'Conflict',
          'message': 'Already exists or overlaps.',
        }, 409),
      ),
    );
    await expectLater(
      api.create(Member.fromJson(memberJson)),
      throwsA(
        predicate(
          (e) => e.toString().contains('HTTP 409: Already exists or overlaps.'),
        ),
      ),
    );
  });
  test('MemberApi rejects an unexpected success status', () async {
    final api = MemberApi(
      client: MockClient((_) async => jsonResponse(memberJson, 200)),
    );
    await expectLater(api.create(Member.fromJson(memberJson)), throwsException);
  });
  test('MemberApi delete accepts an empty 204 without JSON decoding', () async {
    final api = MemberApi(
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/members/7');
        return http.Response('', 204);
      }),
    );
    await api.delete(7);
  });
}
