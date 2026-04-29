// student_login_provider.dart
// Provider for student login and data

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class StudentLoginProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentStudent;
  bool _isLoading = false;

  UserModel? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;

  Future<bool> loginStudent(String registerNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if the user exists in users collection
      final user = await _firebaseService.getUser(registerNumber);
      if (user != null) {
        _currentStudent = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentStudent = null;
    notifyListeners();
  }
}