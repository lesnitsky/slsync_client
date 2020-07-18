import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:slsync_local/src/session.dart';

import 'extensions.dart';
import 'state.dart';

class SLSyncServer {
  static const WHITELIST_ALL = const ['*'];
  static const SRC_ID = 'slsync-src';

  final state = SLSyncState();
  HttpServer server;

  start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    final host = server.address.host;
    final port = server.port;

    stdout.writeln('create:  POST http://$host:$port/:sessionId Body: "id1"');
    stdout.writeln('connect:      ws://$host:$port/:sessionId');

    await handleRequests();
  }

  Future<void> handleRequests() async {
    await for (var req in server) {
      stdout.writeln(req.method + ' ' + req.uri.path);
      final id = extractSessionId(req);

      req.response.headers.add('Access-Control-Allow-Origin', '*');
      req.response.headers.add('Access-Control-Allow-Headers', '*');

      if (id == null) {
        await notFound(req);
        continue;
      }

      if (req.method == 'OPTIONS') {
        req.response.statusCode = 204;
        await req.response.close();
        continue;
      }

      if (req.method == 'POST') {
        await createSession(req, id);
        continue;
      }

      if (req.method == 'GET') {
        await connectClient(req, id);
        continue;
      }

      await notFound(req);
    }
  }

  String extractSessionId(HttpRequest req) {
    try {
      return req.uri.path.split('/')[1];
    } catch (_) {
      return '';
    }
  }

  Future<void> createSession(HttpRequest req, String id) async {
    if (state.sessions.containsKey(id)) {
      req.response.statusCode = 302;
      await req.response.close();
      return;
    }

    final body = (await utf8.decodeStream(req)).toJson() ?? {};

    state.sessions[id] = Session(
      id,
      body['whitelist']?.split(',') ?? WHITELIST_ALL,
    );

    stdout.writeln('Session $id created');

    req.response.statusCode = 200;
    await req.response.close();
  }

  Future<void> connectClient(HttpRequest req, String id) async {
    final session = state.sessions[id];

    if (session == null) {
      return await notFound(req);
    }

    final s = await WebSocketTransformer.upgrade(req);
    session.sockets.add(s);

    final socketStream = s.asBroadcastStream();

    try {
      final srcId = await socketStream.first.timeout(Duration(seconds: 1));
      stdout.writeln('Client $srcId joined session $id');

      if (srcId is! String) {
        throw new Exception('invalid client id');
      }

      bool writeAllowed = session.whitelist == WHITELIST_ALL ||
          session.whitelist.join('') == '*';

      if (!writeAllowed) {
        writeAllowed = session.whitelist.any((w) => w.startsWith(srcId));
      }

      if (writeAllowed) {
        broadcastFrom(srcId, socketStream, session);
      }

      s.done
          .then(disconnect(srcId, s, session))
          .catchError(disconnect(srcId, s, session));
    } catch (err) {
      disconnect('unknown', s, session)(err);
    }
  }

  broadcastFrom(String srcId, Stream socket, Session session) async {
    await for (var event in socket) {
      session.sockets.forEach((socket) {
        stdout.writeln('Broadcasting $event from $srcId to ${session.id}');
        socket.add(event);
      });
    }
  }

  disconnect(String id, WebSocket socket, Session session) {
    return (_) {
      stdout.writeln('Client $id disconnected from ${session.id}');
      socket.close();
      session.sockets.remove(socket);

      if (session.sockets.length == 0) {
        stdout.writeln('Session ${session.id} destroyed; no more clients');
        state.sessions.remove(session.id);
      }
    };
  }

  Future<void> notFound(HttpRequest req) async {
    stderr.writeln('404');
    req.response.statusCode = 404;
    req.response.write('Not found');
    await req.response.flush();
    await req.response.close();
  }
}
