// Resource models: map backend JSON to a meeting room or desk and serialize requests.
class Resource {
  final int id;
  final String name, location, status;
  final int capacity;
  final double hourlyRate;

  const Resource({
    this.id = 0,
    required this.name,
    required this.location,
    required this.capacity,
    required this.hourlyRate,
    required this.status,
  });

  static Resource fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final name = json['name'] as String;
    final location = json['location'] as String;
    final capacity = (json['capacity'] as num).toInt();
    final rate = (json['hourlyRate'] as num).toDouble();
    final status = json['status'] as String;
    if (json.containsKey('deskType')) {
      return Desk(
        id: id,
        name: name,
        location: location,
        hourlyRate: rate,
        status: status,
        deskType: json['deskType'] as String,
      );
    }
    if (json.containsKey('projector') && json.containsKey('videoConference')) {
      return MeetingRoom(
        id: id,
        name: name,
        location: location,
        capacity: capacity,
        hourlyRate: rate,
        status: status,
        projector: json['projector'] as bool,
        videoConference: json['videoConference'] as bool,
      );
    }
    // Some booking responses contain a lazy resource with only its common fields.
    return Resource(
      id: id,
      name: name,
      location: location,
      capacity: capacity,
      hourlyRate: rate,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'capacity': capacity,
    'hourlyRate': hourlyRate,
    'status': status,
  };
}

class MeetingRoom extends Resource {
  final bool projector, videoConference;
  const MeetingRoom({
    super.id,
    required super.name,
    required super.location,
    required super.capacity,
    required super.hourlyRate,
    required super.status,
    required this.projector,
    required this.videoConference,
  });

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'capacity': capacity,
    'hourlyRate': hourlyRate,
    'status': status,
    'projector': projector,
    'videoConference': videoConference,
  };
}

class Desk extends Resource {
  final String deskType;
  const Desk({
    super.id,
    required super.name,
    required super.location,
    required super.hourlyRate,
    required super.status,
    required this.deskType,
  }) : super(capacity: 1);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'capacity': 1,
    'hourlyRate': hourlyRate,
    'status': status,
    'deskType': deskType,
  };
}
