class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final int points;
  final String createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.points,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      points: int.tryParse(json['points'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'points': points,
      'created_at': createdAt,
    };
  }
}
