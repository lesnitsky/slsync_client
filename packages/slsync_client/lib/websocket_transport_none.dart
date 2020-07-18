import 'package:slsync_client/transport.dart';

class WebSocketTransport extends Transport {
  WebSocketTransport({
    String hostname,
    int port,
    String clientId,
  });

  @override
  set clientId(String clientId) {
    throw new Exception('Platform not supported');
  }

  @override
  Future<void> connect(String sessionId) {
    throw new Exception('Platform not supported');
  }

  @override
  Future<void> disconnect() {
    throw new Exception('Platform not supported');
  }

  @override
  send(message) {
    throw new Exception('Platform not supported');
  }
}
