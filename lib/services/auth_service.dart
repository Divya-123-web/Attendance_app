// auth_service.dart
// Handles teacher authentication via Firebase Auth.
// Teachers log in with email + password.
// Students do NOT need to log in — they just go through the 3-step flow.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream that emits whenever auth state changes
  // (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current logged-in user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  // ─────────────────────────────────────────
  // TEACHER SIGN IN
  // ─────────────────────────────────────────
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthException gives specific error codes
      throw Exception(_friendlyError(e.code));
    }
  }

  // ─────────────────────────────────────────
  // CREATE TEACHER ACCOUNT (run once to set up)
  // ─────────────────────────────────────────
  Future<UserCredential> createTeacher(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e.code));
    }
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Convert Firebase error codes to user-friendly messages
  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No teacher account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}