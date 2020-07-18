import 'dart:io';

class Log {
  static i(String message) {
    stdout.writeln('(slsync_client) [I] $message');
  }

  static e(String message) {
    stderr.writeln('(slsync_client) [E] $message');
  }
}
