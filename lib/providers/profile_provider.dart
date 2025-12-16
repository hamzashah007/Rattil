import 'package:flutter/material.dart';
import 'package:rattil/utils/error_handler.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordLoading = false;
  bool get isPasswordLoading => _isPasswordLoading;

  bool _isDeleteLoading = false;
  bool get isDeleteLoading => _isDeleteLoading;

  String? errorMessage;
  void setError(dynamic error) {
    errorMessage = ErrorHandler.getSimpleMessage(error);
    notifyListeners();
  }

  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setPasswordLoading(bool value) {
    _isPasswordLoading = value;
    notifyListeners();
  }

  void setDeleteLoading(bool value) {
    _isDeleteLoading = value;
    notifyListeners();
  }

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }
}
