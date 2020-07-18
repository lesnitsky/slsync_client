import 'package:guaranteed/guaranteed.dart';

typedef Hook = Future<dynamic> Function();

mixin HooksRunner {
  List<Hook> get hooks;

  Future<void> runHooks() async {
    for (var hook in hooks) {
      final runner = CallbackRunner(hook);
      await runner.retryUntilSuccess();
    }
  }
}

abstract class Transport<T> with HooksRunner {
  set clientId(String clientId);

  List<Hook> hooks = [];

  Stream<T> messages;
  send(T message);

  Future<void> connect(String sessionId);
  Future<void> disconnect();
}
