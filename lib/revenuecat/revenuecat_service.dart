import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  Future<PurchaseResult> purchasePackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }

  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  void openCustomerCenter() {
    throw UnimplementedError('Customer support portal is not available in purchases_flutter.');
  }
}
