import 'package:flutter/foundation.dart';

class DownloadBus extends ChangeNotifier {
  static final DownloadBus _instance = DownloadBus._internal();
  factory DownloadBus() => _instance;
  DownloadBus._internal();

  void notifyChanged() {
    notifyListeners();
  }
}
