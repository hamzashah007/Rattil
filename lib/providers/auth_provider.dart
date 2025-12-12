import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rattil/utils/firestore_helpers.dart';
import 'package:rattil/utils/error_handler.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userName;
  String? _userEmail;
  String? _userGender; // Optional

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userGender => _userGender;

  User? get currentUser => FirebaseAuth.instance.currentUser;

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
          _userGender = doc.data()?['gender'];
        } else {
          // Document doesn't exist or name is null, create/update it
          _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
          _userEmail = user.email;
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
      }
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    String? gender, // Optional
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
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
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
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } on FirebaseException catch (e) {
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } catch (e) {
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    }
  }

  /// Deletes the user account and anonymizes all related data (transactions only)
  Future<String?> deleteAccount({
    required String password,
    required BuildContext context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'No user is currently signed in.';
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Re-authenticate user
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);

      // 2. Delete user profile from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // 3. Anonymize all transactions for this user
      final transactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in transactions.docs) {
        await doc.reference.update({
          'userId': 'DELETED_USER',
          'userEmail': 'deleted@account.com',
          'userName': 'Deleted User',
          'isAnonymized': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      // 5. Delete Firebase Auth account
      await user.delete();

      // 6. Clear local state
      _userName = null;
      _userEmail = null;
      _userGender = null;
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      final friendly = ErrorHandler.handleAuthError(e);
      return friendly.message;
    }
  }
}
