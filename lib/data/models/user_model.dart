class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // admin, organizer, exhibitor
  final String company;
  final String phone;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.company = '',
    this.phone = '',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'exhibitor',
      company: map['company'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'company': company,
      'phone': phone,
      'createdAt': createdAt,
    };
  }
}