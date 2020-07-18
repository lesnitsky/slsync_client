import 'dart:async';

import 'dart:typed_data';

mixin HeartbeatMixin {
  Timer _heartbeatTimer;
  EventSink get hbDest;
  Int8List hb = Int8List(2);

  heartbeat() {
    if (_heartbeatTimer != null) return;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      hb[0] = 108;
      hb[1] = 56;
      hbDest.add(hb.buffer);
    });
  }
}
