import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rattil/models/package.dart' as models;
import 'package:rattil/utils/firestore_helpers.dart';

/// Centralized RevenueCat state: offerings, purchases, entitlement access.
/// Follows RevenueCat best practices: dynamic paywalls using offerings and packages.
class RevenueCatProvider extends ChangeNotifier {
  static const apiKey = 'appl_pMSdZUXXAVlzGeftesHFTwvEsiu';
  static const entitlementId = 'Rattil Packages';

  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _started = false;
  bool isLoading = false;
  bool isPurchasing = false;
  String? errorMessage;
  
  // Temporary storage for recently purchased product ID (until RevenueCat server syncs)
  String? _recentlyPurchasedProductId;
  DateTime? _recentPurchaseTime;

  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  
  /// Check if user has active access. Returns false if subscription is cancelled (willRenew = false).
  bool get hasAccess {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    if (entitlement == null) {
      debugPrint('🔍 [RevenueCatProvider] No active entitlement found');
      return false;
    }
    
    // If willRenew is false, subscription is cancelled - no access
    if (!entitlement.willRenew) {
      debugPrint('⚠️ [RevenueCatProvider] Subscription cancelled (willRenew = false) - denying access');
      return false;
    }
    
    debugPrint('✅ [RevenueCatProvider] Active subscription found - granting access');
    return true;
  }

  /// Get available packages from the current offering.
  /// Returns empty list if offerings are not loaded or current offering is null.
  List<Package> get availablePackages {
    if (_offerings?.current == null) return [];
    return _offerings!.current!.availablePackages;
  }

  /// Check if offerings are loaded and current offering has packages.
  bool get hasAvailablePackages => availablePackages.isNotEmpty;

  /// Get the product identifier of the currently subscribed package.
  /// Returns null if user doesn't have access or product ID cannot be determined.
  /// 
  /// IMPORTANT: RevenueCat entitlement.productIdentifier might not always return the correct
  /// product ID if multiple products are linked to the same entitlement. We check activeSubscriptions
  /// first to get the actual purchased product ID.
  String? get subscribedProductId {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    if (entitlement == null) {
      debugPrint('🔍 [RevenueCatProvider] No active entitlement found');
      return null;
    }
    
    // If willRenew is false, subscription is cancelled - return null
    if (!entitlement.willRenew) {
      debugPrint('⚠️ [RevenueCatProvider] Subscription cancelled (willRenew = false) - no product ID');
      return null;
    }
    
    debugPrint('🔍 [RevenueCatProvider] Finding subscribed product ID...');
    debugPrint('   - Entitlement identifier: ${entitlement.identifier}');
    debugPrint('   - Entitlement productIdentifier: ${entitlement.productIdentifier}');
    debugPrint('   - Will renew: ${entitlement.willRenew}');
    
    // FIRST: Check if we have a recently purchased product ID that hasn't synced yet
    debugPrint('   🔍 Checking temporary storage...');
    debugPrint('   - Recently purchased ID: $_recentlyPurchasedProductId');
    debugPrint('   - Recent purchase time: $_recentPurchaseTime');
    
    if (_recentlyPurchasedProductId != null && _recentPurchaseTime != null) {
      final timeSincePurchase = DateTime.now().difference(_recentPurchaseTime!);
      debugPrint('   - Time since purchase: ${timeSincePurchase.inSeconds}s (${timeSincePurchase.inMinutes} minutes)');
      
      // Use temporary product ID if purchase was within last 10 minutes (increased from 5)
      if (timeSincePurchase.inMinutes < 10) {
        debugPrint('   💾 Using recently purchased product ID (not yet synced): $_recentlyPurchasedProductId');
        debugPrint('   ✅ Returning temporary product ID: $_recentlyPurchasedProductId');
        return _recentlyPurchasedProductId;
      } else {
        // Clear if too old (probably won't sync)
        debugPrint('   ⚠️ Recent purchase too old (${timeSincePurchase.inMinutes} minutes), clearing temporary storage');
        _recentlyPurchasedProductId = null;
        _recentPurchaseTime = null;
      }
    } else {
      debugPrint('   ℹ️ No temporary storage found');
    }
    
    // SECOND: Check activeSubscriptions to get the actual purchased product ID
    // This is more reliable than entitlement.productIdentifier when multiple products share the same entitlement
    final activeSubscriptions = _customerInfo?.activeSubscriptions ?? [];
    debugPrint('   - Active subscriptions count: ${activeSubscriptions.length}');
    
    // If multiple subscriptions, we need to find the LATEST/MOST RECENT one
    // Check all entitlements to find the one with the latest purchase date
    String? actualProductId;
    DateTime? latestPurchaseDate;
    
    // Look for product IDs in active subscriptions (01, 02, 03)
    // Handle different formats: "01", "1", "com.rattil.01", "intermediate_02", etc.
    for (final subscriptionId in activeSubscriptions) {
      debugPrint('     - Checking subscription: $subscriptionId');
      
      String? foundProductId;
      
      // Method 1: Exact match for "01", "02", "03"
      if (['01', '02', '03', '1', '2', '3'].contains(subscriptionId)) {
        foundProductId = subscriptionId.padLeft(2, '0');
        debugPrint('       ✅ Found exact match product ID: $foundProductId');
      } else {
        // Method 2: Extract numeric part from subscription ID
        // Handles formats like "01", "02", "03", "com.rattil.02", "product_02", etc.
        final numericMatch = RegExp(r'(\d+)').allMatches(subscriptionId);
        for (final match in numericMatch) {
          final extractedNumber = match.group(1);
          if (extractedNumber != null) {
            final num = int.tryParse(extractedNumber);
            if (num != null && num >= 1 && num <= 3) {
              foundProductId = extractedNumber.padLeft(2, '0');
              debugPrint('       ✅ Found numeric product ID in subscription: $foundProductId');
              break;
            }
          }
        }
        
        // Method 3: Check by product name keywords (case-insensitive)
        if (foundProductId == null) {
          final lowerId = subscriptionId.toLowerCase();
          if (lowerId.contains('basic') || lowerId.contains('01') || lowerId.contains('recitation')) {
            foundProductId = '01';
            debugPrint('       ✅ Found Basic product by name: 01');
          } else if (lowerId.contains('intermediate') || lowerId.contains('02')) {
            foundProductId = '02';
            debugPrint('       ✅ Found Intermediate product by name: 02');
          } else if (lowerId.contains('premium') || lowerId.contains('intensive') || lowerId.contains('03')) {
            foundProductId = '03';
            debugPrint('       ✅ Found Premium product by name: 03');
          }
        }
      }
      
      // If we found a product ID, check its purchase date to find the latest one
      if (foundProductId != null) {
        // Find the entitlement that corresponds to this subscription
        // Check all entitlements to find the one with this product ID and get its purchase date
        for (final entitlementEntry in _customerInfo!.entitlements.all.entries) {
          final ent = entitlementEntry.value;
          if (ent.isActive && ent.productIdentifier == subscriptionId) {
            try {
              final purchaseDate = DateTime.parse(ent.latestPurchaseDate);
              debugPrint('       - Purchase date for $foundProductId: $purchaseDate');
              
              // If this is the first product or has a later purchase date, use it
              if (latestPurchaseDate == null || purchaseDate.isAfter(latestPurchaseDate)) {
                latestPurchaseDate = purchaseDate;
                actualProductId = foundProductId;
                debugPrint('       ✅ Updated to latest product ID: $actualProductId (purchased: $purchaseDate)');
              }
            } catch (e) {
              // If date parsing fails, still use this product ID if we don't have one yet
              if (actualProductId == null) {
                actualProductId = foundProductId;
                debugPrint('       ✅ Using product ID (date parsing failed): $actualProductId');
              }
            }
            break;
          }
        }
        
        // If we couldn't find the entitlement, still use this product ID if we don't have one yet
        if (actualProductId == null) {
          actualProductId = foundProductId;
          debugPrint('       ✅ Using first found product ID: $actualProductId');
        }
      }
    }
    
    // SECOND: If not found in activeSubscriptions, try entitlement.productIdentifier
    if (actualProductId == null) {
      debugPrint('   - Product ID not found in activeSubscriptions, trying entitlement.productIdentifier...');
      final productId = entitlement.productIdentifier;
      debugPrint('   - Entitlement productIdentifier: $productId');
      
      // Try to extract numeric part if it's a full identifier
      final numericMatch = RegExp(r'(\d+)').firstMatch(productId);
      if (numericMatch != null) {
        final extractedNumber = numericMatch.group(1);
        if (extractedNumber != null) {
          actualProductId = extractedNumber.padLeft(2, '0');
          debugPrint('   - Extracted numeric ID from entitlement: $actualProductId');
        }
      } else {
        actualProductId = productId;
      }
    }
    
    // THIRD: Check allPurchasedProductIdentifiers and find the LATEST purchase
    // IMPORTANT: Prioritize products that are in allPurchasedProductIdentifiers but NOT in activeSubscriptions
    // These are recent purchases that haven't synced yet
    if (actualProductId == null || !['01', '02', '03'].contains(actualProductId)) {
      debugPrint('   - Checking allPurchasedProductIdentifiers for LATEST purchase...');
      final allPurchased = _customerInfo?.allPurchasedProductIdentifiers ?? [];
      final activeSubs = _customerInfo?.activeSubscriptions ?? [];
      
      debugPrint('   - All purchased IDs: $allPurchased');
      debugPrint('   - Active subscriptions: $activeSubs');
      
      // Find products that are in allPurchased but NOT in activeSubscriptions (recent purchases)
      final recentPurchases = allPurchased.where((id) => !activeSubs.contains(id)).toList();
      debugPrint('   - Recent purchases (not yet in activeSubscriptions): $recentPurchases');
      
      String? latestProductId;
      DateTime? latestDate;
      
      // FIRST: Check recent purchases (in allPurchased but not in activeSubscriptions)
      // These are the most recent and should be prioritized
      for (final purchasedId in recentPurchases) {
        debugPrint('     - Checking recent purchase (not synced): $purchasedId');
        
        String? foundProductId;
        
        // Method 1: Exact match
        if (['01', '02', '03', '1', '2', '3'].contains(purchasedId)) {
          foundProductId = purchasedId.padLeft(2, '0');
          debugPrint('       ✅ Found exact match: $foundProductId');
        } else {
          // Method 2: Extract numeric part
          final numericMatches = RegExp(r'(\d+)').allMatches(purchasedId);
          for (final match in numericMatches) {
            final extractedNumber = match.group(1);
            if (extractedNumber != null) {
              final num = int.tryParse(extractedNumber);
              if (num != null && num >= 1 && num <= 3) {
                foundProductId = extractedNumber.padLeft(2, '0');
                debugPrint('       ✅ Found numeric product ID: $foundProductId');
                break;
              }
            }
          }
          
          // Method 3: Check by product name keywords
          if (foundProductId == null) {
            final lowerId = purchasedId.toLowerCase();
            if (lowerId.contains('basic') || lowerId.contains('01') || lowerId.contains('recitation')) {
              foundProductId = '01';
              debugPrint('       ✅ Found Basic product by name: 01');
            } else if (lowerId.contains('intermediate') || lowerId.contains('02')) {
              foundProductId = '02';
              debugPrint('       ✅ Found Intermediate product by name: 02');
            } else if (lowerId.contains('premium') || lowerId.contains('intensive') || lowerId.contains('03')) {
              foundProductId = '03';
              debugPrint('       ✅ Found Premium product by name: 03');
            }
          }
        }
        
        // If we found a valid product ID, use it immediately (recent purchases are prioritized)
        if (foundProductId != null && ['01', '02', '03'].contains(foundProductId)) {
          // For recent purchases, use the first one found (they're ordered by purchase time)
          // Or try to get purchase date from entitlement if available
          DateTime? purchaseDate;
          for (final entitlementEntry in _customerInfo!.entitlements.all.entries) {
            final ent = entitlementEntry.value;
            if (ent.isActive) {
              final entProductId = ent.productIdentifier;
              bool matches = false;
              if (entProductId == purchasedId) {
                matches = true;
              } else {
                final numericMatch = RegExp(r'(\d+)').firstMatch(entProductId);
                if (numericMatch != null) {
                  final extracted = numericMatch.group(1);
                  if (extracted != null) {
                    final normalized = extracted.padLeft(2, '0');
                    if (normalized == foundProductId) {
                      matches = true;
                    }
                  }
                }
              }
              
              if (matches) {
                try {
                  purchaseDate = DateTime.parse(ent.latestPurchaseDate);
                  debugPrint('       - Purchase date for $foundProductId: $purchaseDate');
                  break;
                } catch (e) {
                  debugPrint('       ⚠️ Could not parse purchase date: $e');
                }
              }
            }
          }
          
          // Use this product ID if it's newer or if we don't have one yet
          if (latestDate == null) {
            // First product found, use it
            if (purchaseDate != null) {
              latestDate = purchaseDate;
            }
            latestProductId = foundProductId;
            debugPrint('       ✅ Using recent purchase product ID: $latestProductId');
          } else if (purchaseDate != null && purchaseDate.isAfter(latestDate)) {
            // This product is newer, use it
            latestDate = purchaseDate;
            latestProductId = foundProductId;
            debugPrint('       ✅ Updated to newer recent purchase product ID: $latestProductId');
          } else if (latestProductId == null) {
            // No date available but we don't have a product ID yet, use it
            latestProductId = foundProductId;
            debugPrint('       ✅ Using recent purchase product ID (no date): $latestProductId');
          }
          // Don't break - continue to check all recent purchases to find the latest
        }
      }
      
      // SECOND: If no recent purchases found, check all purchased products
      if (latestProductId == null) {
        debugPrint('   - No recent purchases found, checking all purchased products...');
        for (final purchasedId in allPurchased) {
          debugPrint('     - Checking purchased ID: $purchasedId');
          
          String? foundProductId;
          
          // Method 1: Exact match
          if (['01', '02', '03', '1', '2', '3'].contains(purchasedId)) {
            foundProductId = purchasedId.padLeft(2, '0');
            debugPrint('       ✅ Found exact match: $foundProductId');
          } else {
            // Method 2: Extract numeric part
            final numericMatches = RegExp(r'(\d+)').allMatches(purchasedId);
            for (final match in numericMatches) {
              final extractedNumber = match.group(1);
              if (extractedNumber != null) {
                final num = int.tryParse(extractedNumber);
                if (num != null && num >= 1 && num <= 3) {
                  foundProductId = extractedNumber.padLeft(2, '0');
                  debugPrint('       ✅ Found numeric product ID: $foundProductId');
                  break;
                }
              }
            }
            
            // Method 3: Check by product name keywords
            if (foundProductId == null) {
              final lowerId = purchasedId.toLowerCase();
              if (lowerId.contains('basic') || lowerId.contains('01') || lowerId.contains('recitation')) {
                foundProductId = '01';
                debugPrint('       ✅ Found Basic product by name: 01');
              } else if (lowerId.contains('intermediate') || lowerId.contains('02')) {
                foundProductId = '02';
                debugPrint('       ✅ Found Intermediate product by name: 02');
              } else if (lowerId.contains('premium') || lowerId.contains('intensive') || lowerId.contains('03')) {
                foundProductId = '03';
                debugPrint('       ✅ Found Premium product by name: 03');
              }
            }
          }
          
          // If we found a valid product ID, check its purchase date
          if (foundProductId != null && ['01', '02', '03'].contains(foundProductId)) {
            // Find the entitlement that corresponds to this product ID
            for (final entitlementEntry in _customerInfo!.entitlements.all.entries) {
              final ent = entitlementEntry.value;
              // Check if this entitlement's product identifier matches the purchased ID
              if (ent.isActive) {
                final entProductId = ent.productIdentifier;
                // Try to match the product identifier
                bool matches = false;
                if (entProductId == purchasedId) {
                  matches = true;
                } else {
                  // Try numeric extraction
                  final numericMatch = RegExp(r'(\d+)').firstMatch(entProductId);
                  if (numericMatch != null) {
                    final extracted = numericMatch.group(1);
                    if (extracted != null) {
                      final normalized = extracted.padLeft(2, '0');
                      if (normalized == foundProductId) {
                        matches = true;
                      }
                    }
                  }
                }
                
                if (matches) {
                  try {
                    final purchaseDate = DateTime.parse(ent.latestPurchaseDate);
                    debugPrint('       - Purchase date for $foundProductId: $purchaseDate');
                    
                    // If this is the first product or has a later purchase date, use it
                    if (latestDate == null || purchaseDate.isAfter(latestDate)) {
                      latestDate = purchaseDate;
                      latestProductId = foundProductId;
                      debugPrint('       ✅ Updated to LATEST product ID: $latestProductId (purchased: $purchaseDate)');
                    }
                  } catch (e) {
                    debugPrint('       ⚠️ Could not parse purchase date: $e');
                    // If date parsing fails, still use this product ID if we don't have one yet
                    if (latestProductId == null) {
                      latestProductId = foundProductId;
                      debugPrint('       ✅ Using product ID (date parsing failed): $latestProductId');
                    }
                  }
                  break;
                }
              }
            }
          }
        }
      }
      
      // Use the latest product ID if we found one
      if (latestProductId != null) {
        actualProductId = latestProductId;
        debugPrint('   ✅ Using LATEST purchased product ID from allPurchasedProductIdentifiers: $actualProductId');
      }
    }
    
    if (actualProductId != null) {
      debugPrint('✅ [RevenueCatProvider] Found subscribed product ID: $actualProductId');
    } else {
      debugPrint('❌ [RevenueCatProvider] Could not determine subscribed product ID');
    }
    
    return actualProductId;
  }

  /// Check if a specific product ID (01, 02, 03) is the subscribed product.
  /// Handles both "02" and "2" formats for product IDs.
  bool isProductSubscribed(String productId) {
    final subscribedId = subscribedProductId;
    if (subscribedId == null) {
      debugPrint('❌ [RevenueCatProvider] No subscribed product - checking $productId: false');
      return false;
    }
    
    // Normalize both IDs to 2-digit strings for comparison
    final normalizedSubscribedId = subscribedId.padLeft(2, '0');
    final normalizedProductId = productId.padLeft(2, '0');
    
    // Also try integer comparison as fallback
    final isSubscribed = normalizedSubscribedId == normalizedProductId ||
        (int.tryParse(subscribedId) != null && 
         int.tryParse(productId) != null && 
         int.parse(subscribedId) == int.parse(productId));
    
    debugPrint('🔎 [RevenueCatProvider] Checking if $productId is subscribed:');
    debugPrint('   - Subscribed ID (raw): $subscribedId');
    debugPrint('   - Subscribed ID (normalized): $normalizedSubscribedId');
    debugPrint('   - Checking ID (raw): $productId');
    debugPrint('   - Checking ID (normalized): $normalizedProductId');
    debugPrint('   - Match result: $isSubscribed');
    
    return isSubscribed;
  }

  late final CustomerInfoUpdateListener _customerInfoListener;

  RevenueCatProvider() {
    _customerInfoListener = _handleCustomerInfo;
  }

  /// Call once after Purchases.configure has run.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _refreshAll();
    Purchases.addCustomerInfoUpdateListener(_customerInfoListener);
  }

  Future<void> _refreshAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([refreshCustomerInfo(), refreshOfferings()]);
    } catch (e) {
      errorMessage = _friendlyMessageForCode(null, e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCustomerInfo() async {
    debugPrint('🔄 [RevenueCatProvider] Refreshing customer info...');
    try {
      final info = await Purchases.getCustomerInfo();
      debugPrint('✅ [RevenueCatProvider] Customer info refreshed successfully');
      _setCustomerInfo(info);
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error refreshing customer info: $e');
      rethrow;
    }
  }

  Future<void> refreshOfferings() async {
    debugPrint('🔄 [RevenueCatProvider] Refreshing offerings...');
    try {
      _offerings = await Purchases.getOfferings();
      debugPrint('✅ [RevenueCatProvider] Offerings refreshed successfully');
      
      if (_offerings?.current != null) {
        debugPrint('   - Current offering ID: ${_offerings!.current!.identifier}');
        debugPrint('   - Available packages: ${_offerings!.current!.availablePackages.length}');
        for (final pkg in _offerings!.current!.availablePackages) {
          debugPrint('     • Package: ${pkg.identifier}');
          debugPrint('       - Store Product ID: ${pkg.storeProduct.identifier}');
          debugPrint('       - Store Product Title: ${pkg.storeProduct.title}');
          debugPrint('       - Store Product Price: ${pkg.storeProduct.priceString}');
          debugPrint('       - Package Type: ${pkg.packageType}');
        }
      } else {
        debugPrint('   ⚠️ No current offering found');
      }
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error refreshing offerings: $e');
      rethrow;
    }
    notifyListeners();
  }

  /// Purchase a package directly. Best practice: use packages from offerings.
  /// [packageToPurchase] should come from [availablePackages] or [offerings.current.availablePackages].
  Future<CustomerInfo?> purchasePackage(Package packageToPurchase) async {
    debugPrint('💳 [RevenueCatProvider] ========== PURCHASE PACKAGE ==========');
    debugPrint('   - Package Identifier: ${packageToPurchase.identifier}');
    debugPrint('   - Store Product ID: ${packageToPurchase.storeProduct.identifier}');
    debugPrint('   - Store Product Title: ${packageToPurchase.storeProduct.title}');
    debugPrint('   - Store Product Price: ${packageToPurchase.storeProduct.priceString}');
    debugPrint('   - Package Type: ${packageToPurchase.packageType}');
    
    final expectedProductId = packageToPurchase.storeProduct.identifier;
    
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await Purchases.purchasePackage(packageToPurchase);
      final info = result.customerInfo;
      debugPrint('✅ [RevenueCatProvider] Purchase completed successfully');
      debugPrint('   - Customer Info received');
      
      // IMPORTANT: Store the purchased product ID temporarily until RevenueCat server syncs
      // Store BEFORE setting customer info to ensure it's available immediately
      _recentlyPurchasedProductId = expectedProductId;
      _recentPurchaseTime = DateTime.now();
      debugPrint('   💾 Stored recently purchased product ID: $_recentlyPurchasedProductId');
      debugPrint('   💾 Purchase time: $_recentPurchaseTime');
      
      // IMPORTANT: RevenueCat server might take a moment to sync the purchase
      // Retry customer info refresh to get the latest purchase
      debugPrint('🔄 [RevenueCatProvider] Verifying purchase sync...');
      debugPrint('   - Expected product ID: $expectedProductId');
      
      // Check if the purchased product ID is in the customer info
      final allPurchased = info.allPurchasedProductIdentifiers;
      final activeSubs = info.activeSubscriptions;
      final hasExpectedProduct = allPurchased.contains(expectedProductId);
      final hasExpectedInActiveSubs = activeSubs.contains(expectedProductId);
      
      // Check if entitlement's productIdentifier matches
      final entitlement = info.entitlements.active[entitlementId];
      final entitlementMatches = entitlement?.productIdentifier == expectedProductId;
      
      debugPrint('   - All purchased IDs: $allPurchased');
      debugPrint('   - Active subscriptions: $activeSubs');
      debugPrint('   - Has expected product in allPurchased: $hasExpectedProduct');
      debugPrint('   - Has expected product in activeSubscriptions: $hasExpectedInActiveSubs');
      debugPrint('   - Entitlement productIdentifier matches: $entitlementMatches');
      
      // IMPORTANT: Only clear temporary storage if product ID is in activeSubscriptions OR entitlement matches
      // If it's only in allPurchased but not in activeSubscriptions, keep temporary storage
      if (!hasExpectedProduct) {
        // Product ID not found at all - retry logic
        debugPrint('   ⚠️ Expected product ID not found yet, retrying customer info refresh...');
        debugPrint('   💾 Temporary storage preserved: $_recentlyPurchasedProductId');
        
        for (int attempt = 1; attempt <= 2; attempt++) {
          await Future.delayed(Duration(seconds: attempt)); // 1s, 2s delays (much faster)
          debugPrint('   - Retry attempt $attempt/2...');
          try {
            final refreshedInfo = await Purchases.getCustomerInfo();
            
            // IMPORTANT: Don't clear temporary storage when calling _setCustomerInfo during retry
            // Only update customer info, keep temporary storage intact
            _customerInfo = refreshedInfo;
            notifyListeners();
            
            final refreshedPurchased = refreshedInfo.allPurchasedProductIdentifiers;
            final refreshedActiveSubs = refreshedInfo.activeSubscriptions;
            final refreshedEntitlement = refreshedInfo.entitlements.active[entitlementId];
            final refreshedEntitlementMatches = refreshedEntitlement?.productIdentifier == expectedProductId;
            
            debugPrint('   - Refreshed purchased IDs: $refreshedPurchased');
            debugPrint('   - Refreshed active subscriptions: $refreshedActiveSubs');
            debugPrint('   💾 Temporary storage still preserved: $_recentlyPurchasedProductId');
            
            // Check if product ID is in activeSubscriptions OR entitlement matches
            if (refreshedPurchased.contains(expectedProductId) && 
                (refreshedActiveSubs.contains(expectedProductId) || refreshedEntitlementMatches)) {
              debugPrint('   ✅ Expected product ID synced (in activeSubscriptions or entitlement matches)!');
              // Clear temporary storage as it's now synced
              _recentlyPurchasedProductId = null;
              _recentPurchaseTime = null;
              _setCustomerInfo(refreshedInfo); // Now update with full logging
              return refreshedInfo;
            }
          } catch (e) {
            debugPrint('   ⚠️ Retry failed: $e');
            debugPrint('   💾 Temporary storage still preserved: $_recentlyPurchasedProductId');
          }
        }
        debugPrint('   ⚠️ Expected product ID still not found after retries, but purchase was successful');
        debugPrint('   💾 Will use temporarily stored product ID: $_recentlyPurchasedProductId');
        // IMPORTANT: Keep temporary storage intact - don't clear it
        // Set customer info but preserve temporary storage
        _customerInfo = info;
        notifyListeners();
      } else if (!hasExpectedInActiveSubs && !entitlementMatches) {
        // Product ID found in allPurchased but NOT in activeSubscriptions AND entitlement doesn't match
        // This means purchase is successful but RevenueCat server hasn't synced yet
        debugPrint('   ⚠️ Product ID found in allPurchased but NOT in activeSubscriptions or entitlement');
        debugPrint('   💾 Keeping temporary storage until activeSubscriptions/entitlement syncs');
        debugPrint('   💾 Temporary storage preserved: $_recentlyPurchasedProductId');
        // Keep temporary storage intact - don't clear it
        _customerInfo = info;
        notifyListeners();
      } else {
        // Product ID found in activeSubscriptions OR entitlement matches
        debugPrint('   ✅ Expected product ID synced (in activeSubscriptions or entitlement matches), clearing temporary storage');
        _recentlyPurchasedProductId = null;
        _recentPurchaseTime = null;
        _setCustomerInfo(info);
      }
      
      // Save transaction to Firebase after successful purchase
      await _saveTransactionToFirebase(
        packageToPurchase: packageToPurchase,
        customerInfo: info,
        productId: expectedProductId,
      );
      
      return info;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      errorMessage = _friendlyMessageForCode(code, e.message);
      return null;
    } catch (e) {
      errorMessage = _friendlyMessageForCode(null, e.toString());
      return null;
    } finally {
      isPurchasing = false;
      notifyListeners();
    }
  }

  /// Find a RevenueCat package by matching store product identifier.
  /// This matches UI packages (id: 01, 02, 03) to RevenueCat packages.
  /// Returns null if not found. Best practice: use this to match UI to RevenueCat packages dynamically.
  Package? findPackageByStoreProductId(String storeProductId) {
    if (_offerings?.current == null) return null;
    for (final pkg in _offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == storeProductId) {
        return pkg;
      }
    }
    return null;
  }

  Future<CustomerInfo?> restorePurchases() async {
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      _setCustomerInfo(info);
      return info;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      errorMessage = _friendlyMessageForCode(code, e.message);
      return null;
    } catch (e) {
      errorMessage = _friendlyMessageForCode(null, e.toString());
      return null;
    } finally {
      isPurchasing = false;
      notifyListeners();
    }
  }

  /// Opens RevenueCat Customer Center.
  /// 
  /// NOTE: Customer Center is a native UI provided by RevenueCat SDK that displays
  /// subscription information directly from App Store Connect.
  /// 
  /// If all packages show "Basic Recitation" in Customer Center:
  /// 1. This is a known issue with RevenueCat SDK's Customer Center UI
  /// 2. The issue is NOT in our code - Customer Center is a native component
  /// 3. Possible causes:
  ///    - App Store Connect data sync delay (can take 24-48 hours)
  ///    - RevenueCat cache issue (may need to wait for cache refresh)
  ///    - Product identifier mapping issue in RevenueCat dashboard
  /// 
  /// Solutions to try:
  /// 1. Wait 24-48 hours for App Store Connect changes to sync
  /// 2. Check RevenueCat dashboard → Apps & Providers → App Store Connect API credentials
  /// 3. Verify product identifiers match in RevenueCat dashboard
  /// 4. Contact RevenueCat support if issue persists
  /// 
  /// The prices are correctly fetched, indicating the connection is working.
  /// Only the display names may show incorrectly due to sync/cache issues.
  Future<void> openCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      errorMessage = _friendlyMessageForCode(null, e.toString());
      notifyListeners();
    }
  }


  void _setCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    
    // Comprehensive debugging for customer info
    debugPrint('📊 [RevenueCatProvider] ========== CUSTOMER INFO UPDATE ==========');
    debugPrint('   - App User ID: ${info.originalAppUserId}');
    debugPrint('   - First Seen: ${info.firstSeen}');
    debugPrint('   - Request Date: ${info.requestDate}');
    
    // Check all entitlements
    debugPrint('   - All Entitlements (${info.entitlements.all.length}):');
    info.entitlements.all.forEach((key, entitlement) {
      debugPrint('     • $key:');
      debugPrint('       - Identifier: ${entitlement.identifier}');
      debugPrint('       - Product Identifier: ${entitlement.productIdentifier}');
      debugPrint('       - Is Active: ${entitlement.isActive}');
      debugPrint('       - Will Renew: ${entitlement.willRenew}');
      debugPrint('       - Latest Purchase Date: ${entitlement.latestPurchaseDate}');
      debugPrint('       - Expiration Date: ${entitlement.expirationDate}');
      debugPrint('       - Period Type: ${entitlement.periodType}');
    });
    
    // Check active entitlements
    debugPrint('   - Active Entitlements (${info.entitlements.active.length}):');
    info.entitlements.active.forEach((key, entitlement) {
      debugPrint('     ✅ $key:');
      debugPrint('       - Product ID: ${entitlement.productIdentifier}');
      debugPrint('       - Will Renew: ${entitlement.willRenew}');
    });
    
    // Check for our specific entitlement
    final ourEntitlement = info.entitlements.active[entitlementId];
    if (ourEntitlement != null) {
      debugPrint('   ✅ [RevenueCatProvider] Found our entitlement "$entitlementId":');
      debugPrint('       - Product ID: ${ourEntitlement.productIdentifier}');
      debugPrint('       - Will Renew: ${ourEntitlement.willRenew}');
    } else {
      debugPrint('   ❌ [RevenueCatProvider] Entitlement "$entitlementId" NOT FOUND in active entitlements');
      debugPrint('       - Available active entitlements: ${info.entitlements.active.keys.toList()}');
    }
    
    // Check all active subscriptions
    debugPrint('   - Active Subscriptions (${info.activeSubscriptions.length}):');
    for (final subscriptionId in info.activeSubscriptions) {
      debugPrint('     • $subscriptionId');
    }
    
    // Check all purchased product identifiers
    debugPrint('   - All Purchased Product IDs (${info.allPurchasedProductIdentifiers.length}):');
    for (final productId in info.allPurchasedProductIdentifiers) {
      debugPrint('     • $productId');
    }
    
    debugPrint('📊 [RevenueCatProvider] ==========================================');
    
    notifyListeners();
  }

  void _handleCustomerInfo(CustomerInfo info) {
    _setCustomerInfo(info);
  }

  String? _friendlyMessageForCode(PurchasesErrorCode? code, String? message) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'Network issue. Please try again.';
      case PurchasesErrorCode.purchaseInvalidError:
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchase not allowed on this device/account.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. Please wait or check the store app.';
      case PurchasesErrorCode.storeProblemError:
        return null; // Don't show error message for store problems
      default:
        return message ?? 'Something went wrong. Please try again.';
    }
  }

  /// Save transaction to Firebase after successful IAP purchase
  Future<void> _saveTransactionToFirebase({
    required Package packageToPurchase,
    required CustomerInfo customerInfo,
    required String productId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ [RevenueCatProvider] No user logged in, skipping transaction save');
        return;
      }

      // Get user info
      final userId = user.uid;
      final userEmail = user.email ?? '';
      final userName = user.displayName ?? (userEmail.isNotEmpty ? userEmail.split('@')[0] : 'User');

      // Get package name from UI model
      String packageName = packageToPurchase.storeProduct.title;
      // Try to match with our package model for better name
      try {
        final productIdInt = int.tryParse(productId);
        if (productIdInt != null) {
          final matchingPackage = models.packages.firstWhere(
            (pkg) => pkg.id == productIdInt,
            orElse: () => models.packages.first,
          );
          packageName = matchingPackage.name;
        }
      } catch (e) {
        debugPrint('⚠️ [RevenueCatProvider] Could not match package name, using store product title: $e');
      }

      // Get transaction details from RevenueCat
      final entitlement = customerInfo.entitlements.active[entitlementId];
      
      // Get Apple transaction ID from the latest transaction
      // RevenueCat doesn't directly expose transaction ID, so we'll use a combination
      final appleTransactionId = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Get amount from package
      final amount = packageToPurchase.storeProduct.price;
      final currency = packageToPurchase.storeProduct.currencyCode.isNotEmpty 
          ? packageToPurchase.storeProduct.currencyCode 
          : 'USD';
      
      // Get expiry date from entitlement
      DateTime? expiryDate;
      final expirationDateStr = entitlement?.expirationDate;
      if (expirationDateStr != null && expirationDateStr.isNotEmpty) {
        try {
          expiryDate = DateTime.parse(expirationDateStr);
        } catch (e) {
          debugPrint('⚠️ [RevenueCatProvider] Could not parse expiry date: $e');
        }
      }

      // Save transaction to Firebase
      debugPrint('💾 [RevenueCatProvider] Saving transaction to Firebase...');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Package: $packageName');
      debugPrint('   - Product ID: $productId');
      debugPrint('   - Amount: $amount $currency');
      
      await FirestoreHelpers.createTransaction(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        appleTransactionId: appleTransactionId,
        productId: productId,
        packageName: packageName,
        amount: amount,
        currency: currency,
        subscriptionId: entitlement?.identifier,
        expiryDate: expiryDate,
      );
      
      debugPrint('✅ [RevenueCatProvider] Transaction saved to Firebase successfully');
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error saving transaction to Firebase: $e');
      // Don't throw error - transaction saving failure shouldn't break purchase flow
    }
  }

  @override
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_customerInfoListener);
    super.dispose();
  }
}

