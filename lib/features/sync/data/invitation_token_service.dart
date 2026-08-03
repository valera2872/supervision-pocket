import 'dart:convert';

import 'package:crypto/crypto.dart';

class InvitationTokenService {
  const InvitationTokenService();

  String sha256Hex(String rawToken) {
    final token = rawToken.trim();
    if (token.isEmpty) {
      throw ArgumentError.value(rawToken, 'rawToken', 'Token cannot be empty');
    }
    return sha256.convert(utf8.encode(token)).toString();
  }
}
