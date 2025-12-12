import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper functions for managing Firestore data in Rattil app
/// 
/// Note: Rattil provides online classes conducted by instructors.
/// Learning progress and bookmarks are NOT tracked in the app.

class FirestoreHelpers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== TRANSACTION HELPERS ====================
  
  /// Create a new transaction record after successful IAP purchase
  static Future<void> createTransaction({
    required String userId,
    required String userEmail,
    required String userName,
    required String appleTransactionId,
    required String productId,
    required String packageName,
    required double amount,
    required String currency,
    String? subscriptionId,
    DateTime? expiryDate,
  }) async {
    final transactionId = _firestore.collection('transactions').doc().id;
    
    await _firestore.collection('transactions').doc(transactionId).set({
      'transactionId': transactionId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'appleTransactionId': appleTransactionId,
      'productId': productId,
      'packageName': packageName,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'platform': 'ios',
      'purchaseDate': FieldValue.serverTimestamp(),
      'expiryDate': expiryDate,
      'status': 'active',
      'isAnonymized': false,
    });
  }

  /// Update transaction status (e.g., when subscription expires or is cancelled)
  static Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    DateTime? cancelledDate,
    DateTime? refundedDate,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
    };
    
    if (cancelledDate != null) {
      updates['cancelledDate'] = Timestamp.fromDate(cancelledDate);
    }
    
    if (refundedDate != null) {
      updates['refundedDate'] = Timestamp.fromDate(refundedDate);
    }
    
    await _firestore.collection('transactions').doc(transactionId).update(updates);
  }

  /// Get user's transaction history
  static Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isAnonymized', isEqualTo: false)
        .orderBy('purchaseDate', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ==================== USER SUBSCRIPTION HELPERS ====================
  
  /// Update user's subscription status
  static Future<void> updateUserSubscription({
    required String userId,
    required String subscriptionStatus,
    String? currentPackage,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionStatus': subscriptionStatus,
      'currentPackage': currentPackage,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if user has active subscription
  static Future<bool> hasActiveSubscription(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) return false;
    
    final data = userDoc.data();
    return data?['subscriptionStatus'] == 'active';
  }
}
