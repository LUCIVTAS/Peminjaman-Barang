class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' atau 'user'

  UserModel({required this.uid, required this.email, required this.role});

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
    );
  }
}