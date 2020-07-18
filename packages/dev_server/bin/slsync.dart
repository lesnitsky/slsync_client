import 'package:slsync_local/src/server.dart';

void main() async {
  final server = SLSyncServer();
  await server.start();
}
