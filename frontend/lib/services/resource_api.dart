import 'package:http/http.dart' as http;

import '../models/booking.dart';
import 'booking_api.dart';

class ResourceApi {
  final http.Client _client = http.Client();
  late final BookingApi _api;
  ResourceApi({String? base}) {
    _api = BookingApi(
      base ??
          const String.fromEnvironment(
            'COWORK_API_BASE',
            defaultValue: 'http://localhost:8080/api',
          ),
      _client,
    );
  }

  Future<List<dynamic>> getResources() async =>
      await _api.request('GET', 'resources') as List;
  Future<void> addMeetingRoom(Json room) async {
    await _api.request('POST', 'resources/rooms', body: room);
  }

  Future<void> addDesk(Json desk) async {
    await _api.request('POST', 'resources/desks', body: desk);
  }

  Future<void> updateMeetingRoom(int id, Json room) async {
    await _api.request('PUT', 'resources/rooms/$id', body: room);
  }

  Future<void> updateDesk(int id, Json desk) async {
    await _api.request('PUT', 'resources/desks/$id', body: desk);
  }

  Future<void> deleteResource(int id) async {
    await _api.request('DELETE', 'resources/$id');
  }

  void close() => _client.close();
}
