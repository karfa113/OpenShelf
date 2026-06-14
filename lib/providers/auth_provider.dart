import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _initialized = false;

  AuthProvider() {
    _user = _service.currentUser;
    _sub = _service.userChanges.listen((u) {
      _user = u;
      _initialized = true;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isInitialized => _initialized;

  Future<String?> signIn(String email, String password) async {
    try {
      await _service.signInEmail(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanize(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _service.signUpEmail(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanize(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signInGoogle() async {
    try {
      await _service.signInWithGoogle();
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanize(e);
    } catch (_) {
      return 'Google sign-in failed. Please try again.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanize(e);
    } catch (_) {
      return 'Could not send reset email. Please try again.';
    }
  }

  Future<void> signOut() => _service.signOut();

  String _humanize(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
