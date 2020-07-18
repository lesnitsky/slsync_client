abstract class Runner<T> {
  Runner();
  Future<T> run();
  onError(dynamic err, StackTrace stackTrace);
}

class StopRetryException {}

Iterable<Duration> fibbonaciIntervals(int maxSteps) sync* {
  List<int> seq = [0];

  for (int i = 0; i < maxSteps; i++) {
    yield Duration(seconds: seq.last);

    if (seq.length == 1) {
      seq.add(1);
    }

    int last = seq.last;
    seq.removeAt(0);
    seq.add(last + seq.first);
  }

  while (true) {
    yield Duration(seconds: seq.last);
  }
}

mixin Retry<T> on Runner<T> {
  Iterable<Duration> retryIntervals = fibbonaciIntervals(7);

  Future<T> retryUntilSuccess() async {
    int attempt = 0;

    while (true) {
      try {
        final waitDuration = retryIntervals.elementAt(attempt);
        await Future.delayed(waitDuration);
        attempt++;
        return await run();
      } on StopRetryException {
        return null;
      } catch (err, stackTrace) {
        onError(err, stackTrace);
      }
    }
  }
}

class CallbackRunner extends Runner<void> with Retry {
  static Function(Error err, StackTrace stackTrace) reportError;

  Future<dynamic> Function() callback;

  CallbackRunner(this.callback);

  @override
  Future<void> run() async {
    await callback();
  }

  onError(dynamic err, StackTrace stackTrace) {
    reportError?.call(err, stackTrace);
  }
}

mixin PrintErrorReporter {
  onError(dynamic err, StackTrace stackTrace) {
    print(err.toString());
    print(stackTrace.toString());
  }
}
