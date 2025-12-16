import 'package:flutter/material.dart';
import 'package:rattil/utils/error_handler.dart';

class PackagesProvider extends ChangeNotifier {
  int _selectedIndex = 1;
  int _purchasingIndex = -1; // Track which package is being purchased (-1 = none)

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

  int get purchasingIndex => _purchasingIndex;

  void setPurchasingIndex(int index) {
    _purchasingIndex = index;
    notifyListeners();
  }

  void clearPurchasingIndex() {
    _purchasingIndex = -1;
    notifyListeners();
  }
}
