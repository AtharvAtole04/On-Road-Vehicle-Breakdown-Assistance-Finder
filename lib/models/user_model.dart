class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'user', 'admin', 'mechanic'
  final bool isApproved;
  final String? garageName;
  final double walletBalance;
  final double? liveLat;
  final double? liveLng;
  final String? phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isApproved = false,
    this.garageName,
    this.walletBalance = 0.0,
    this.liveLat,
    this.liveLng,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      isApproved: map['isApproved'] ?? false,
      garageName: map['garageName'],
      walletBalance: (map['walletBalance'] is num) ? (map['walletBalance'] as num).toDouble() : 0.0,
      liveLat: (map['liveLat'] is num) ? (map['liveLat'] as num).toDouble() : null,
      liveLng: (map['liveLng'] is num) ? (map['liveLng'] as num).toDouble() : null,
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'garageName': garageName,
      'walletBalance': walletBalance,
      'liveLat': liveLat,
      'liveLng': liveLng,
      'phone': phone,
    };
  }
}
