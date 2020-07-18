import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:guaranteed/guaranteed.dart';

import 'extensions.dart';
import 'session.dart';
import 'websocket_transport.dart';

class CreateSessionRunner extends Runner<Session>
    with Retry, PrintErrorReporter {
  final String hostname;
  final int port;
  final String sessionId;
  final List<String> whitelist;
  final String clientId;

  CreateSessionRunner({
    this.hostname,
    this.port,
    this.sessionId,
    this.whitelist,
    this.clientId,
  });

  @override
  Future<Session> run() async {
    final res = await http.post(
      'http://$hostname${port.toPort()}/$sessionId',
      headers: {
        'content-type': 'application/json',
      },
      body: json.encode({'whitelist': whitelist.join(',')}),
    );

    if (res.statusCode == 200 || res.statusCode == 302) {
      final session = Session(id: sessionId, whitelist: whitelist);

      if (session.transport != null) {
        return session;
      }

      final transport = WebSocketTransport(
        clientId: clientId,
        hostname: hostname,
        port: port,
      );

      transport.hooks.add(() async => await run());
      session.transport = transport;

      session.clientId = clientId;
      return session;
    } else {
      throw new Exception('Failed to create session $sessionId');
    }
  }
}

class SLSyncHttpClient {
  final String hostname;
  final int port;
  CreateSessionRunner createSessionRunner;

  SLSyncHttpClient({this.hostname, this.port = 80}) : assert(hostname != null);

  Future<Session> createSession({
    String sessionId,
    String clientId,
    List<String> whitelist = const ['*'],
  }) async {
    createSessionRunner = CreateSessionRunner(
      clientId: clientId,
      hostname: hostname,
      port: port,
      sessionId: sessionId,
      whitelist: whitelist,
    );

    return await createSessionRunner.retryUntilSuccess();
  }
}
