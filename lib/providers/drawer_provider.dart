import 'package:flutter/material.dart';

class DrawerProvider extends ChangeNotifier {
  bool _isDrawerOpen = false;
  bool get isDrawerOpen => _isDrawerOpen;

  void setDrawerOpen(bool value) {
    _isDrawerOpen = value;
    notifyListeners();
  }

  void openDrawer() {
    _isDrawerOpen = true;
    notifyListeners();
  }

  void closeDrawer() {
    _isDrawerOpen = false;
    notifyListeners();
  }
}
