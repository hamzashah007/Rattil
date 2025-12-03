import 'package:flutter/material.dart';

class PackagesProvider extends ChangeNotifier {
  int _selectedIndex = 1;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Add more state and methods as needed for your packages screen
}
