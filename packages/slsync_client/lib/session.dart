import 'transport.dart';

class Session<T> {
  static final Map<String, Session> _instances = {};

  final String id;
  final List<String> whitelist;

  String _clientId;

  String get clientId => _clientId;

  set clientId(String id) {
    _clientId = id;
    transport.clientId = id;
  }

  Transport<T> transport;

  Stream<T> get messages => transport.messages;

  factory Session({String id, List<String> whitelist}) =>
      _instances[id] ??= Session._internal(id: id, whitelist: whitelist);

  Session._internal({
    this.id,
    this.whitelist = const ['*'],
  });

  Future<void> join() async {
    assert(transport != null, 'no transport found');
    assert(clientId != null, 'clientId not set');

    await transport.connect(id);
  }

  Future<void> leave() async {
    await transport.disconnect();
  }

  void send(T message) async {
    await transport.send(message);
  }
}
