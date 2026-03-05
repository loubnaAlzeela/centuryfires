import 'package:flutter/material.dart';

class OrderTypeController extends ChangeNotifier {
  String _type = 'delivery';

  String get type => _type;

  void setType(String value) {
    _type = value;
    notifyListeners();
  }
}
