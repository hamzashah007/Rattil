import 'package:flutter/material.dart';
import 'package:rattil/utils/error_handler.dart';

class HomeProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  String? errorMessage;
  void setError(dynamic error) {
    errorMessage = ErrorHandler.getSimpleMessage(error);
    notifyListeners();
  }

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
