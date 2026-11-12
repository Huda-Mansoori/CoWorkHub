typedef Json = Map<String, dynamic>;

class Resource {
  final int id;
  final String name, location, status;
  final int capacity;
  final double rate;
  Resource.fromJson(Json j)
    : id = j['id'],
      name = j['name'],
      location = j['location'],
      status = j['status'],
      capacity = j['deskType'] != null ? 1 : j['capacity'],
      rate = (j['hourlyRate'] as num).toDouble();
}

class Member {
  final int id;
  final String name;
  Member.fromJson(Json j)
    : id = int.parse(j['id'].toString()),
      name = j['fullName'] ?? j['name'];
}

class Reservation {
  final int memberId, resourceId, attendees;
  final DateTime start, end;
  const Reservation(
    this.memberId,
    this.resourceId,
    this.attendees,
    this.start,
    this.end,
  );
  Json toJson() => {
    'memberId': memberId,
    'resourceId': resourceId,
    'attendees': attendees,
    'startDateTime': start.toIso8601String(),
    'endDateTime': end.toIso8601String(),
  };
  Reservation.fromJson(Json j)
    : this(
        j['memberId'] ?? j['member']['id'],
        j['resourceId'] ?? j['resource']['id'],
        j['attendees'],
        DateTime.parse(j['startDateTime']),
        DateTime.parse(j['endDateTime']),
      );
}

class Booking {
  final int id;
  final Reservation slot;
  final String status;
  final double cost;
  const Booking(this.id, this.slot, this.status, this.cost);
  Booking.fromJson(Json j)
    : this(
        j['id'],
        Reservation.fromJson(j),
        j['status'],
        (j['totalCost'] as num).toDouble(),
      );
  bool conflicts(int resourceId, DateTime start, DateTime end) =>
      status == 'CONFIRMED' &&
      slot.resourceId == resourceId &&
      slot.start.isBefore(end) &&
      slot.end.isAfter(start);
}
