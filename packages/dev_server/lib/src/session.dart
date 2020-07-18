import 'dart:io';

class Session {
  final String id;
  final List<String> whitelist;
  final List<WebSocket> sockets = [];

  Session(this.id, this.whitelist);
}
