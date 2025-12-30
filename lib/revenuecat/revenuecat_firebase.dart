import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'revenuecat_constants.dart';

class RevenueCatFirebase {
  static Future<void> logPurchase(CustomerInfo info) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final entitlement = info.entitlements.active[entitlementId];
    if (entitlement == null) return;
    try {
      await FirebaseFirestore.instance.collection('revenuecat_purchases').add({
        'userId': user.uid,
        'entitlementId': entitlementId,
        'productIdentifier': entitlement.productIdentifier,
        'latestPurchaseDate': entitlement.latestPurchaseDate,
        'expirationDate': entitlement.expirationDate,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
