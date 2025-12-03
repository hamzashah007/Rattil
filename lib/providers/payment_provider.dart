import 'package:flutter/material.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  // Add more state and methods as needed for your payment screen
}
