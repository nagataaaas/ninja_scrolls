import 'package:flutter/material.dart';

class ReaderProvider extends ChangeNotifier {
  Widget? _endDrawer;

  Widget? get endDrawer => _endDrawer;

  set endDrawer(Widget? value) {
    _endDrawer = value;
    notifyListeners();
  }
}
