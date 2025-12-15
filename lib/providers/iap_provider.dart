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
    debugPrint('[IAPProvider] Constructor called. Initializing store info and purchase stream.');
    initStoreInfo();
    _purchaseStream = _iap.purchaseStream;
    _subscription = _purchaseStream.listen(
      (purchaseDetailsList) async {
        debugPrint('[IAPProvider] Purchase stream update: ${purchaseDetailsList.map((p) => 'id:${p.productID}, status:${p.status}, pending:${p.pendingCompletePurchase}').toList()}');
        purchases = purchaseDetailsList;
        for (var purchase in purchaseDetailsList) {
          debugPrint('[IAPProvider] Handling purchase: id=${purchase.productID}, status=${purchase.status}, error=${purchase.error}');
          if (purchase.status == PurchaseStatus.purchased) {
            debugPrint('[IAPProvider] Purchase completed: ${purchase.productID}');
            // TODO: Validate purchase, unlock content, and record in Firestore
          }
          if (purchase.status == PurchaseStatus.error) {
            debugPrint('[IAPProvider] Purchase error: ${purchase.error}');
          }
        }
        notifyListeners();
      },
      onError: (error) {
        setError(error);
        debugPrint('[IAPProvider] Purchase stream error: $error');
      },
    );
  }

  void setError(dynamic error) {
    debugPrint('[IAPProvider] setError called: $error');
    errorMessage = ErrorHandler.getSimpleMessage(error);
    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    debugPrint('[IAPProvider] clearError called');
    errorMessage = null;
    notifyListeners();
  }

  Future<void> initStoreInfo() async {
    isLoading = true;
    debugPrint('[IAPProvider] initStoreInfo called. Querying store info...');
    notifyListeners();
    try {
      isAvailable = await _iap.isAvailable();
      debugPrint('[IAPProvider] Store isAvailable: $isAvailable');
      if (!isAvailable) {
        isLoading = false;
        notifyListeners();
        debugPrint('[IAPProvider] Store not available.');
        return;
      }
      final response = await _iap.queryProductDetails(_productIds.toSet());
      debugPrint('[IAPProvider] Product details response: ${response.productDetails.map((p) => 'id:${p.id}, title:${p.title}').toList()}');
      products = response.productDetails;
      isLoading = false;
      clearError();
      notifyListeners();
    } catch (e) {
      debugPrint('[IAPProvider] Exception in initStoreInfo: $e');
      setError(e);
    }
  }

  Future<void> refreshProducts() async {
    debugPrint('[IAPProvider] refreshProducts called');
    await initStoreInfo();
  }

  void buy(ProductDetails product) {
    debugPrint('[IAPProvider] buy called for product: ${product.id}');
    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam); // For subscriptions
  }

  @override
  void dispose() {
    debugPrint('[IAPProvider] dispose called. Cancelling subscription.');
    _subscription.cancel();
    super.dispose();
  }
}
