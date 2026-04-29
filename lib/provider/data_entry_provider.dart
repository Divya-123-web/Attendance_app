// data_entry_provider.dart
// Provider for managing data entry state

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

enum DataEntryState { idle, saving, success, error }

class DataEntryProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  File? _selectedImage;
  DataEntryState _state = DataEntryState.idle;
  String _errorMessage = '';

  // Getters
  UserModel? get user => _user;
  File? get selectedImage => _selectedImage;
  DataEntryState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isSaving => _state == DataEntryState.saving;

  // Set selected image
  void setSelectedImage(File image) {
    _selectedImage = image;
    notifyListeners();
  }

  // Clear selected image
  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Save user data
  Future<bool> saveUser(UserModel user) async {
    _setSaving();
    _user = user;

    try {
      await _firebaseService.saveUser(user, _selectedImage);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Clear form for next user
  void clearForm() {
    _user = null;
    _selectedImage = null;
    _state = DataEntryState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  void _setSaving() {
    _state = DataEntryState.saving;
    _errorMessage = '';
    notifyListeners();
  }

  void _setSuccess() {
    _state = DataEntryState.success;
    notifyListeners();
  }

  void _setError(String message) {
    _state = DataEntryState.error;
    _errorMessage = message.replaceAll('Exception: ', '');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _state = DataEntryState.idle;
    notifyListeners();
  }
}