// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:async';

import 'package:guaranteed/guaranteed.dart';

import 'transport.dart';

import 'extensions.dart';
import 'heartbeat_mixin.dart';

class ConnectRunner extends Runner<WebSocket> with Retry, PrintErrorReporter {
  final String host;
  final int port;
  final String sessionId;

  ConnectRunner({
    this.host,
    this.port,
    this.sessionId,
  });

  @override
  Future<WebSocket> run() async {
    final s = WebSocket('ws://$host${port.toPort()}/$sessionId');
    s.binaryType = 'arraybuffer';

    await s.onOpen.first;
    return s;
  }
}

class SocketSink extends EventSink {
  final WebSocket socket;

  SocketSink(this.socket);

  @override
  void add(event) {
    socket.send(event);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {}

  @override
  void close() {
    socket.close();
  }
}

class WebSocketTransport<T> extends Transport<T> with HeartbeatMixin {
  final String hostname;
  final int port;
  String clientId;

  WebSocketTransport({this.hostname, this.port, this.clientId});

  WebSocket _socket;

  StreamController<T> _messagesController = StreamController<T>();
  Stream<T> get messages => _messagesController.stream;

  EventSink hbDest;

  @override
  Future<void> connect(String sessionId) async {
    await runHooks();

    _socket = await ConnectRunner(
      host: hostname,
      port: port,
      sessionId: sessionId,
    ).retryUntilSuccess();

    _socket.send(clientId);

    hbDest = SocketSink(_socket);

    _socket.onClose.listen((event) async {
      await connect(sessionId);
    });

    _socket.onMessage.listen((event) {
      _messagesController.add(event.data);
    });
  }

  @override
  Future<void> disconnect() async {
    _socket.close();
    _messagesController.close();
    hbDest.close();
  }

  @override
  send(T message) {
    _socket.send(message);
  }
}
