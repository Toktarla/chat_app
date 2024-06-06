import 'package:bcrypt/bcrypt.dart';

class PasswordHasher {
  // Method to hash a password
  static String hashPassword(String password) {
    final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    return hashedPassword;
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }
}