// Member model: reads member responses and writes editable member fields.
class Member {
  final int id;
  final String fullName, email;
  const Member({this.id = 0, required this.fullName, required this.email});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'fullName': fullName, 'email': email};
}
