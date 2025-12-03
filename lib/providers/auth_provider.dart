import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'uid': credential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'email-already-in-use') return 'Email already in use.';
      if (e.code == 'weak-password') return 'Password is too weak.';
      return e.message ?? 'Sign up failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Sign up failed';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Wrong password provided.';
      return e.message ?? 'Sign in failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Sign in failed';
    }
  }
}
