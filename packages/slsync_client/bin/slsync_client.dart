import 'dart:convert';
import 'dart:io';

import 'package:slsync_client/http_client.dart';
import 'package:slsync_client/session.dart';

void clear() {
  stdout.write('\x1B[2J\x1B[0;0H');
}

int messagesToSkip = 0;

void main(List<String> args) async {
  int port = 3000;

  try {
    port = int.parse(args.first);
  } catch (_) {}

  final c = SLSyncHttpClient(hostname: '127.0.0.1', port: port);

  Session s;

  final messages = stdin.transform(utf8.decoder).asBroadcastStream();

  Future<String> read() async {
    messagesToSkip++;
    return (await messages.first).replaceAll('\n', '');
  }

  clear();
  print('Service port: $port');
  stdout.write('Session id: ');
  final id = await read();
  stdout.write('Client id: ');
  final clientId = await read();

  stdout.write('Whitelist (coma separated): ');

  final whitelist = (await read()).split(',');

  s = await c.createSession(
    clientId: clientId,
    sessionId: id,
    whitelist: whitelist,
  );

  s.join().listen((event) {
    print('${DateTime.now()} [Session $id]: $event');
  });

  messages.listen((event) {
    s.send(event.replaceAll('\n', ''));
  });
}
