import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userName;
  String? _userEmail;
  String? _userAvatarUrl;
  String? _userGender;

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userAvatarUrl => _userAvatarUrl;
  String? get userGender => _userGender;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Fetch user data from Firestore
  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()?['name'] != null) {
          _userName = doc.data()?['name'];
          _userEmail = doc.data()?['email'] ?? user.email;
          _userAvatarUrl = doc.data()?['avatarUrl'];
          _userGender = doc.data()?['gender'];
        } else {
          // Document doesn't exist or name is null, create/update it
          _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
          _userEmail = user.email;
          _userAvatarUrl = user.photoURL;
          
          // Create document if it doesn't exist
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _userName,
            'email': _userEmail,
            'uid': user.uid,
          }, SetOptions(merge: true));
        }
        print('Fetched user: $_userName, $_userEmail');
      } catch (e) {
        print('Error fetching user data: $e');
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        _userEmail = user.email;
        _userAvatarUrl = user.photoURL;
      }
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String gender,
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
        'gender': gender,
        'uid': credential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Sign out after account creation so user has to sign in manually
      await FirebaseAuth.instance.signOut();
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') return 'Email already in use.';
      if (e.code == 'weak-password') return 'Password is too weak.';
      if (e.code == 'invalid-email') return 'Invalid email address.';
      return e.message ?? 'Sign up failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('SignUp Error: $e');
      return 'Sign up failed: ${e.toString()}';
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
      await fetchUserData(); // Fetch user data after login
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

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _userName = null;
    _userEmail = null;
    _userAvatarUrl = null;
    notifyListeners();
  }

  // Forgot Password - sends reset email
  Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found with this email.';
      if (e.code == 'invalid-email') return 'Invalid email address.';
      return e.message ?? 'Failed to send reset email';
    } catch (e) {
      return 'Failed to send reset email';
    }
  }
}
