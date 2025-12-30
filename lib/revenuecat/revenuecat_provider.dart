import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenuecat_service.dart';
import 'revenuecat_firebase.dart';
import 'revenuecat_constants.dart';

class RevenueCatProvider extends ChangeNotifier with WidgetsBindingObserver {
  final RevenueCatService _service = RevenueCatService();

  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool isLoading = false;
  bool isPurchasing = false;
  bool isRestoringPurchases = false;
  String? errorMessage;

  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;

  bool get hasAccess =>
      _customerInfo?.entitlements.active[entitlementId] != null;

  RevenueCatProvider() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await refreshOfferings();
    await refreshCustomerInfo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      refreshCustomerInfo();
    }
  }

  Future<void> refreshOfferings() async {
    try {
      isLoading = true;
      notifyListeners();
      _offerings = await _service.getOfferings();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load offerings: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCustomerInfo() async {
    try {
      isLoading = true;
      notifyListeners();
      _customerInfo = await _service.getCustomerInfo();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load customer info: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      isPurchasing = true;
      notifyListeners();
      final result = await _service.purchasePackage(package);
      _customerInfo = result.customerInfo;
      errorMessage = null;
      await RevenueCatFirebase.logPurchase(result.customerInfo);
      notifyListeners();
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isPurchasing = false;
      notifyListeners();
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    try {
      isRestoringPurchases = true;
      notifyListeners();
      final info = await _service.restorePurchases();
      _customerInfo = info;
      errorMessage = null;
      notifyListeners();
      return info;
    } catch (e) {
      errorMessage = 'Failed to restore purchases: $e';
      notifyListeners();
      return null;
    } finally {
      isRestoringPurchases = false;
      notifyListeners();
    }
  }

  void openCustomerCenter() {
    _service.openCustomerCenter();
  }
}
