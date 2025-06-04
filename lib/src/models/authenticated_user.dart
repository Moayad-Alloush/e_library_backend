// lib/src/models/authenticated_user.dart
class AuthenticatedUser {

  const AuthenticatedUser({
    required this.userId,
    required this.isAdmin,
  });
  final int userId;
  final bool isAdmin;
}