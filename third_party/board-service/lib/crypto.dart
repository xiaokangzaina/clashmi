import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class Crypto {
  static List<int>? _key;

  static String configure(String? encoded) {
    if (encoded != null) {
      try {
        final key = base64Decode(encoded);
        if (key.length == 32) {
          _key = key;
          return encoded;
        }
      } on FormatException {
        // A new key invalidates tokens saved under a damaged key.
      }
    }
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    _key = key;
    return base64Encode(key);
  }

  static Encrypter _cipher(String account) {
    final derived = Hmac(sha256, _key!).convert(utf8.encode(account));
    return Encrypter(
      AES(Key.fromBase64(base64Encode(derived.bytes)), mode: AESMode.gcm),
    );
  }

  static String encrypt(String account, String value) {
    if (value.isEmpty || _key == null) return '';
    final iv = IV.fromSecureRandom(12);
    final encrypted = _cipher(account).encrypt(value, iv: iv);
    return 'gcm1.${iv.base64}.${encrypted.base64}';
  }

  static String decrypt(String account, String value) {
    final parts = value.split('.');
    if (_key == null || parts.length != 3 || parts.first != 'gcm1') return '';
    try {
      return _cipher(
        account,
      ).decrypt(Encrypted.fromBase64(parts[2]), iv: IV.fromBase64(parts[1]));
    } on Exception {
      return '';
    } on ArgumentError {
      return '';
    }
  }
}
