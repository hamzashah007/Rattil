import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'package:rattil/utils/error_handler.dart';

class IAPProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final List<String> _productIds = ['01', '02', '03']; // App Store Product IDs

  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isLoading = false;
  List<PurchaseDetails> purchases = [];
  late final Stream<List<PurchaseDetails>> _purchaseStream;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  String? errorMessage;

  IAPProvider() {
    initStoreInfo();
    _purchaseStream = _iap.purchaseStream;
    _subscription = _purchaseStream.listen(
      (purchaseDetailsList) async {
        purchases = purchaseDetailsList;
        for (var purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.purchased) {
            // TODO: Validate purchase, unlock content, and record in Firestore
            // Example: await validateAndUnlock(purchase);
            // Navigation to subscriber dashboard (if context is available)
            // Use a callback or event to trigger navigation in the UI
          }
          // Handle other statuses if needed
        }
        notifyListeners();
      },
      onError: (error) {
        setError(error);
        debugPrint('IAP purchase stream error: $error');
      },
    );
  }

  void setError(dynamic error) {
    errorMessage = ErrorHandler.getSimpleMessage(error);
    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> initStoreInfo() async {
    isLoading = true;
    notifyListeners();
    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        isLoading = false;
        notifyListeners();
        return;
      }
      final response = await _iap.queryProductDetails(_productIds.toSet());
      products = response.productDetails;
      isLoading = false;
      clearError();
      notifyListeners();
    } catch (e) {
      setError(e);
    }
  }

  Future<void> refreshProducts() async {
    await initStoreInfo();
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
