// ResourceApi: explicit HTTP methods and JSON mapping for resources.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/resource.dart';
import 'api_config.dart';
import 'http_error.dart';

class ResourceApi {
  final http.Client client;
  final bool _ownsClient;
  ResourceApi({http.Client? client})
    : client = client ?? http.Client(),
      _ownsClient = client == null;

  // TRACE: page -> ResourceApi.fetchAll -> GET /api/resources
  // -> ResourceController.getAllResources -> ResourceService -> ResourceRepository.findAll -> MySQL
  // <- 200 JSON -> Resource.fromJson -> page setState -> list rebuilds.
  Future<List<Resource>> fetchAll() async {
    final uri = Uri.parse('$apiBaseUrl/resources');
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Resource.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // TRACE: Availability -> ResourceApi.fetchAvailable -> GET /api/resources/available
  // -> AvailabilityController -> BookingService.getAvailableResources
  // -> ResourceRepository.findByStatus + BookingRepository.hasOverlappingBooking -> MySQL
  // <- 200 JSON -> Resource.fromJson -> page setState -> available cards.
  Future<List<Resource>> fetchAvailable(DateTime start, DateTime end) async {
    final uri = Uri.parse('$apiBaseUrl/resources/available').replace(
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Resource.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // TRACE: page -> ResourceApi.create -> POST /api/resources/segment
  // -> ResourceController -> ResourceService.createResource
  // -> ResourceRepository.save -> MySQL <- 201 JSON -> Resource.fromJson -> page reload.
  Future<Resource> create(Resource draft) async {
    String segment = 'rooms';
    if (draft is Desk) segment = 'desks';
    final uri = Uri.parse('$apiBaseUrl/resources/$segment');
    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 201) throw httpError(response);
    return Resource.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // TRACE: page -> ResourceApi.update -> PUT /api/resources/segment/id
  // -> ResourceController -> ResourceService.updateResource
  // -> ResourceRepository.save -> MySQL <- 200 JSON -> Resource.fromJson -> page reload.
  Future<Resource> update(int id, Resource draft) async {
    String segment = 'rooms';
    if (draft is Desk) segment = 'desks';
    final uri = Uri.parse('$apiBaseUrl/resources/$segment/$id');
    final response = await client
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(draft.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw httpError(response);
    return Resource.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // TRACE: page -> ResourceApi.delete -> DELETE /api/resources/{id}
  // -> ResourceController.deleteResource -> ResourceService.deleteResource
  // -> ResourceRepository.delete -> MySQL <- 204 -> page reload; booking history gives 409.
  Future<void> delete(int id) async {
    final uri = Uri.parse('$apiBaseUrl/resources/$id');
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
