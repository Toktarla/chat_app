import 'package:flutter/material.dart';

class CallProvider extends ChangeNotifier {
  dynamic _incomingSDPOffer;

  dynamic get incomingSDPOffer => _incomingSDPOffer;

  set incomingSDPOffer(dynamic value) {
    _incomingSDPOffer = value;
    notifyListeners();
  }

  void resetIncomingSDPOffer() {
    _incomingSDPOffer = null;
    notifyListeners();
  }
}
