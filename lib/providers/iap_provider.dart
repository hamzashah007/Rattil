import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class IAPProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final List<String> _productIds = ['01', '02', '03']; // App Store Product IDs

  List<ProductDetails> products = [];
  bool isAvailable = false;
  List<PurchaseDetails> purchases = [];
  late final Stream<List<PurchaseDetails>> _purchaseStream;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  IAPProvider() {
    initStoreInfo();
    _purchaseStream = _iap.purchaseStream;
    _subscription = _purchaseStream.listen(
      (purchaseDetailsList) {
        purchases = purchaseDetailsList;
        for (var purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.purchased) {
            // TODO: Unlock subscription, validate, and record in Firestore
          }
          // Handle other statuses if needed
        }
        notifyListeners();
      },
      onError: (error) {
        // Handle errors from the purchase stream
        debugPrint('IAP purchase stream error: $error');
      },
    );
  }

  Future<void> initStoreInfo() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      notifyListeners();
      return;
    }
    final response = await _iap.queryProductDetails(_productIds.toSet());
    products = response.productDetails;
    notifyListeners();
  }

  void buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam); // For subscriptions
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
