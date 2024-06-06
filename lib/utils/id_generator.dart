import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class IdGenerator {
  static String generateRandomMessageId() {
    final String randomString = Random().nextInt(1000000).toString();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$randomString-$timestamp';
  }

  static String getChatId(String userUid1, String userUid2) {
    List<String> sortedIds = [userUid1, userUid2]..sort();
    String concatenatedIds = sortedIds.join();
    List<int> bytes = utf8.encode(concatenatedIds);
    Digest hash = sha256.convert(bytes);
    String hashString = hash.toString();
    return hashString.substring(0, 12);
  }

  static String generateGroupId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const length = 12;
    var random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
