import 'package:flutter/material.dart';
import 'package:rattil/utils/error_handler.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;

  String? errorMessage;
  void setError(dynamic error) {
    errorMessage = ErrorHandler.getSimpleMessage(error);
    notifyListeners();
  }

  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }
  // Add more state and methods as needed for your profile screen

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }
}
