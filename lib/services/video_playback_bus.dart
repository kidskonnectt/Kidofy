import 'package:flutter/foundation.dart';

class VideoPlaybackBus {
  static final ValueNotifier<int> _pauseSignal = ValueNotifier<int>(0);

  static ValueNotifier<int> get pauseSignal => _pauseSignal;

  static void pauseAll() {
    _pauseSignal.value++;
  }
}
