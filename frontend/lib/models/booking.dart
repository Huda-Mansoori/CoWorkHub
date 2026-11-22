// Booking model: reads nested member/resource responses and writes booking request IDs.
import 'member.dart';
import 'resource.dart';

class Booking {
  final int id;
  final Member member;
  final Resource resource;
  final DateTime startDateTime, endDateTime;
  final int attendees;
  final String status;
  final double totalCost;

  const Booking({
    this.id = 0,
    required this.member,
    required this.resource,
    required this.startDateTime,
    required this.endDateTime,
    required this.attendees,
    this.status = 'CONFIRMED',
    this.totalCost = 0,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: (json['id'] as num).toInt(),
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      resource: Resource.fromJson(json['resource'] as Map<String, dynamic>),
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      attendees: (json['attendees'] as num).toInt(),
      status: json['status'] as String,
      totalCost: (json['totalCost'] as num).toDouble(),
    );
  }

  // Only request fields are sent; the backend owns ID, status and totalCost.
  Map<String, dynamic> toJson() => {
    'memberId': member.id,
    'resourceId': resource.id,
    'startDateTime': startDateTime.toIso8601String(),
    'endDateTime': endDateTime.toIso8601String(),
    'attendees': attendees,
  };
}
