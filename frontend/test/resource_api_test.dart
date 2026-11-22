// ResourceApi tests: HTTP paths, JSON bodies, expected status codes and backend messages.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/models/resource.dart';
import 'package:frontend/services/resource_api.dart';

import 'fixtures.dart';

void main() {
  test('ResourceApi GET decodes a typed list', () async {
    final api = ResourceApi(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/resources');
        return jsonResponse([roomJson]);
      }),
    );
    expect(await api.fetchAll(), hasLength(1));
  });
  test('ResourceApi create expects 201 and sends request fields', () async {
    final api = ResourceApi(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), Resource.fromJson(roomJson).toJson());
        return jsonResponse(roomJson, 201);
      }),
    );
    expect((await api.create(Resource.fromJson(roomJson))).id, 2);
  });
  test('ResourceApi update expects 200', () async {
    final api = ResourceApi(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/resources/rooms/7');
        return jsonResponse(roomJson);
      }),
    );
    await api.update(7, Resource.fromJson(roomJson));
  });
  test('ResourceApi exposes the backend 409 message', () async {
    final api = ResourceApi(
      client: MockClient(
        (_) async => jsonResponse({
          'status': 409,
          'error': 'Conflict',
          'message': 'Already exists or overlaps.',
        }, 409),
      ),
    );
    await expectLater(
      api.create(Resource.fromJson(roomJson)),
      throwsA(
        predicate(
          (e) => e.toString().contains('HTTP 409: Already exists or overlaps.'),
        ),
      ),
    );
  });
  test('ResourceApi rejects an unexpected success status', () async {
    final api = ResourceApi(
      client: MockClient((_) async => jsonResponse(roomJson, 200)),
    );
    await expectLater(api.create(Resource.fromJson(roomJson)), throwsException);
  });
  test(
    'ResourceApi delete accepts an empty 204 without JSON decoding',
    () async {
      final api = ResourceApi(
        client: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/resources/7');
          return http.Response('', 204);
        }),
      );
      await api.delete(7);
    },
  );
  test('Availability encodes start/end query parameters', () async {
    final api = ResourceApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/resources/available');
        expect(request.url.queryParameters, {
          'start': '2026-11-24T09:00:00.000',
          'end': '2026-11-24T10:00:00.000',
        });
        return jsonResponse([roomJson]);
      }),
    );
    await api.fetchAvailable(
      DateTime(2026, 11, 24, 9),
      DateTime(2026, 11, 24, 10),
    );
  });
  test('Desk create and update use desk subtype paths', () async {
    final api = ResourceApi(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          expect(request.url.path, '/api/resources/desks');
          return jsonResponse(deskJson, 201);
        }
        expect(request.url.path, '/api/resources/desks/3');
        return jsonResponse(deskJson);
      }),
    );
    final draft = Resource.fromJson(deskJson);
    await api.create(draft);
    await api.update(3, draft);
  });
}
