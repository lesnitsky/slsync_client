import 'dart:async';
import 'dart:io';

import 'package:guaranteed/guaranteed.dart';

import 'protocol.dart';
import 'transport.dart';
import 'extensions.dart';
import 'heartbeat_mixin.dart';

class ConnectRunner extends Runner<WebSocket> with Retry, PrintErrorReporter {
  final String hostname;
  final int port;
  final String sessionId;

  ConnectRunner({this.hostname, this.port, this.sessionId});

  @override
  Future<WebSocket> run() async {
    return await WebSocket.connect('ws://$hostname${port.toPort()}/$sessionId');
  }
}

class WebSocketTransport<T> extends Transport<T> with HeartbeatMixin {
  final String hostname;
  final int port;

  String clientId;

  WebSocket _socket;

  WebSocketTransport({this.clientId, this.hostname, this.port});

  StreamController<T> _messagesController = StreamController<T>();
  Stream<T> get messages => _messagesController.stream;

  @override
  EventSink get hbDest => _socket;

  @override
  Future<void> connect(String sessionId) async {
    await runHooks();

    final r = ConnectRunner(
      hostname: hostname,
      port: port,
      sessionId: sessionId,
    );

    _socket = await r.retryUntilSuccess();
    _socket.add(clientId);

    _socket.done.then((_) async => await connect(sessionId));
    _socket.done.catchError((_) async => await connect(sessionId));

    heartbeat();

    _socket.cast<T>().forEach((event) {
      _messagesController.add(event);
    });
  }

  @override
  Future<void> disconnect() async {
    await _socket.close();
    _messagesController.close();
  }

  void send(T message) {
    _socket.add(message);
  }
}
