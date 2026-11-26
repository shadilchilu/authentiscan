import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashService {
  static String generateHash(String productId, String serial) {
    final bytes = utf8.encode(productId + serial);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
