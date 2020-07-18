import 'dart:convert';

extension JsonExtensions on String {
  toJson() {
    try {
      return json.decode(this);
    } catch (_) {
      return null;
    }
  }
}

extension Base64Json on String {
  String decodeBase64() {
    return utf8.decode(base64.decode(this));
  }
}
