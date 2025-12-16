import 'package:flutter/foundation.dart';
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
  /// 
  /// Uses composite index: userId (Ascending), isAnonymized (Ascending), purchaseDate (Descending)
  /// This provides better performance by filtering at the database level.
  static Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    try {
      // Use composite index for optimal performance
      // Index: userId (Ascending), isAnonymized (Ascending), purchaseDate (Descending)
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('isAnonymized', isEqualTo: false)
          .orderBy('purchaseDate', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Fallback if index is not ready yet (still building)
      debugPrint('⚠️ Composite index not ready, using fallback query: $e');
      // Fallback: Query without isAnonymized filter and filter in memory
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();
      
      // Filter out anonymized transactions in memory
      final transactions = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['isAnonymized'] != true)
          .toList();
      
      return transactions;
    }
  }

  // ==================== USER SUBSCRIPTION HELPERS ====================
  // 
  // ⚠️ DEPRECATED: Subscription status is now managed by RevenueCat, not Firebase.
  // Use RevenueCatProvider instead:
  // - revenueCat.hasAccess (for subscription access)
  // - revenueCat.subscribedProductId (for current package)
  // - revenueCat.customerInfo (for full subscription details)
  //
  // These methods are kept for backward compatibility but should NOT be used.
  // They will be removed in a future version.
  
  /// @deprecated Use RevenueCatProvider.hasAccess instead
  /// 
  /// Update user's subscription status in Firebase.
  /// 
  /// ⚠️ DEPRECATED: Subscription status is managed by RevenueCat, not Firebase.
  /// Do not use this method. Use RevenueCatProvider instead.
  @Deprecated('Use RevenueCatProvider for subscription management. This method will be removed in a future version.')
  static Future<void> updateUserSubscription({
    required String userId,
    required String subscriptionStatus,
    String? currentPackage,
  }) async {
    // Method kept for backward compatibility but does nothing
    // Subscription status is managed by RevenueCat, not Firebase
    debugPrint('⚠️ WARNING: updateUserSubscription() is deprecated. Use RevenueCatProvider instead.');
  }

  /// @deprecated Use RevenueCatProvider.hasAccess instead
  /// 
  /// Check if user has active subscription in Firebase.
  /// 
  /// ⚠️ DEPRECATED: Subscription status is managed by RevenueCat, not Firebase.
  /// Do not use this method. Use RevenueCatProvider.hasAccess instead.
  @Deprecated('Use RevenueCatProvider.hasAccess instead. This method will be removed in a future version.')
  static Future<bool> hasActiveSubscription(String userId) async {
    // Method kept for backward compatibility but always returns false
    // Subscription status is managed by RevenueCat, not Firebase
    debugPrint('⚠️ WARNING: hasActiveSubscription() is deprecated. Use RevenueCatProvider.hasAccess instead.');
    return false;
  }
}
