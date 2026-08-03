import 'dart:convert';

class ConnectionInvitationSecret {
  const ConnectionInvitationSecret({
    required this.uri,
    required this.inviteToken,
    required this.connectionKey,
    this.keyVersion = 1,
  });

  final Uri uri;
  final String inviteToken;
  final List<int> connectionKey;
  final int keyVersion;

  factory ConnectionInvitationSecret.parse(Uri uri) {
    final inviteToken = uri.queryParameters['invite']?.trim() ?? '';
    final fragment = Uri.splitQueryString(uri.fragment);
    final encodedKey = fragment['key']?.trim() ?? '';
    final keyVersion = int.tryParse(fragment['v'] ?? '') ?? 1;
    if (inviteToken.isEmpty || encodedKey.isEmpty) {
      throw const FormatException('Invitation link is incomplete');
    }
    final connectionKey = decodeBase64Url(encodedKey);
    if (connectionKey.length != 32) {
      throw const FormatException('Invitation key must contain 32 bytes');
    }
    return ConnectionInvitationSecret(
      uri: uri,
      inviteToken: inviteToken,
      connectionKey: connectionKey,
      keyVersion: keyVersion,
    );
  }
}

class EncryptedSyncPayload {
  const EncryptedSyncPayload({
    required this.schemaVersion,
    required this.keyVersion,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  final int schemaVersion;
  final int keyVersion;
  final String nonce;
  final String cipherText;
  final String mac;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'keyVersion': keyVersion,
        'nonce': nonce,
        'cipherText': cipherText,
        'mac': mac,
      };

  factory EncryptedSyncPayload.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'] as int?;
    final keyVersion = json['keyVersion'] as int?;
    final nonce = json['nonce'] as String?;
    final cipherText = json['cipherText'] as String?;
    final mac = json['mac'] as String?;
    if (schemaVersion == null ||
        keyVersion == null ||
        nonce == null ||
        cipherText == null ||
        mac == null) {
      throw const FormatException('Encrypted payload is incomplete');
    }
    return EncryptedSyncPayload(
      schemaVersion: schemaVersion,
      keyVersion: keyVersion,
      nonce: nonce,
      cipherText: cipherText,
      mac: mac,
    );
  }
}

String encodeBase64Url(List<int> bytes) {
  return base64UrlEncode(bytes).replaceAll('=', '');
}

List<int> decodeBase64Url(String value) {
  return base64Url.decode(base64Url.normalize(value));
}
