# Firestore Database Structure for Rattil

**Note:** Rattil provides **online classes conducted by instructors**. The app does not track learning progress, bookmarks, or performance as classes are delivered live and managed by teachers.

---

## 📊 Collections Overview (2 Total)

### 1. **users** (User Profile Data Only)
```javascript
users/{userId}
{
  "name": "string",
  "email": "string", 
  "gender": "string|null",
  "uid": "string",
  "createdAt": "timestamp",
  "lastUpdatedAt": "timestamp",
  "avatarUrl": "string|null"
  // ❌ Subscription data NOT stored here - use RevenueCat instead
}
```

**⚠️ Important:** Subscription status is **NOT** stored in Firebase. 
- **RevenueCat** is the source of truth for all subscription data
- Use `RevenueCatProvider` to check subscription status:
  - `revenueCat.hasAccess` - Check if user has active subscription
  - `revenueCat.subscribedProductId` - Get current package ID
  - `revenueCat.customerInfo` - Full subscription details

### 2. **transactions** (Payment & Subscription History)
```javascript
transactions/{transactionId}
{
  "transactionId": "string (unique)",
  "userId": "string",
  "userEmail": "string",
  "userName": "string",
  
  // Apple IAP Data
  "appleTransactionId": "string",
  "productId": "string (e.g., com.rattil.monthly)",
  "packageName": "string (e.g., Premium Intensive)",
  "subscriptionId": "string|null",
  
  // Financial Data
  "amount": "number",
  "currency": "string (USD)",
  "platform": "ios|android",
  
  // Dates
  "purchaseDate": "timestamp",
  "expiryDate": "timestamp|null",
  "cancelledDate": "timestamp|null",
  "refundedDate": "timestamp|null",
  
  // Status
  "status": "active|expired|cancelled|refunded",
  "receiptData": "string (base64)",
  
  // Anonymization tracking
  "deletedAt": "timestamp|null",
  "isAnonymized": "boolean"
}
```

---

## 🗑️ Account Deletion Strategy

### ✅ DELETE COMPLETELY:
- ❌ `users/{userId}` - User profile (name, email, gender, avatar)
- ❌ Firebase Auth account - Authentication credentials

### 🔒 ANONYMIZE (Keep for Legal/Financial Compliance):
- ✏️ **`transactions/*`** where userId matches
  - Set: `userId = "DELETED_USER"`
  - Set: `userEmail = "deleted@account.com"`
  - Set: `userName = "Deleted User"`
  - Set: `isAnonymized = true`
  - Set: `deletedAt = serverTimestamp()`
  - **Keep**: All financial data (amount, productId, dates, appleTransactionId, status)

**Why Anonymize Instead of Delete?**
- **Apple IAP Compliance**: Transaction history required for refunds/disputes
- **Tax Regulations**: Financial records must be retained (typically 7 years)
- **GDPR Compliant**: Personal data removed, financial data anonymized
- **Fraud Prevention**: Detect subscription abuse patterns

---

## 💻 Implementation (Account Deletion Flow)

### Step-by-Step Process:
```dart
// lib/providers/auth_provider.dart - deleteAccount() method

1. Re-authenticate user with password ✅
2. Delete user profile: users/{uid}.delete() ✅
3. Anonymize transactions: Update all matching docs ✅
4. Delete Firebase Auth account: user.delete() ✅
5. Clear local state & navigate to Sign In ✅
```

### Helper Functions Available:
```dart
// lib/utils/firestore_helpers.dart

// Create transaction after IAP purchase
FirestoreHelpers.createTransaction(
  userId: user.uid,
  userEmail: user.email!,
  userName: user.displayName!,
  appleTransactionId: '2000000123456789',
  productId: 'com.rattil.premium_intensive_monthly',
  packageName: 'Premium Intensive',
  amount: 9.99,
  currency: 'USD',
  subscriptionId: 'sub_abc123',
  expiryDate: DateTime.now().add(Duration(days: 30)),
);

// Update transaction status (cancellation/refund)
FirestoreHelpers.updateTransactionStatus(
  transactionId: 'trans_123',
  status: 'cancelled',
  cancelledDate: DateTime.now(),
);

// Get user's transaction history
final transactions = await FirestoreHelpers.getUserTransactions(user.uid);

// ⚠️ DEPRECATED: Do NOT use these methods for subscription status
// Use RevenueCatProvider instead:
final revenueCat = context.read<RevenueCatProvider>();
final hasAccess = revenueCat.hasAccess; // Check subscription access
final subscribedProductId = revenueCat.subscribedProductId; // Get current package
final customerInfo = revenueCat.customerInfo; // Full subscription details
```

---

## ✅ Apple App Store Compliance

### Guideline 5.1.1(v) Requirements:
✅ **In-app deletion** - Delete Account button in Profile → General tab  
✅ **Clear warning** - Dialog explains what will be deleted  
✅ **Password confirmation** - Secure deletion process  
✅ **Complete removal** - All personal data deleted or anonymized  

### Privacy Policy Text:
```
Account Deletion:
Users can delete their account at any time through the app settings. 
Upon deletion:
- Your profile information (name, email, preferences) will be permanently deleted
- Your transaction history will be anonymized for legal and financial compliance
- You will no longer be able to access your account or enrolled classes

Note: Transaction records are anonymized but retained to comply with financial 
regulations and to process any pending refunds through Apple's payment system.
```

---

## 🧪 Testing Checklist

### Before App Store Submission:
- [ ] Test account deletion with active subscription
- [ ] Verify user profile is deleted from Firestore
- [ ] Confirm transactions are anonymized (userId = "DELETED_USER")
- [ ] Check user cannot sign in after deletion
- [ ] Test wrong password scenario
- [ ] Test network error during deletion
- [ ] Verify navigation to Sign In screen works
- [ ] Check Firebase Console for anonymized data
- [ ] Test on both iOS and Android
- [ ] Verify keyboard dismiss functionality

---

## 🎯 Why This Structure?

Since Rattil provides **online classes conducted by instructors**:
- ❌ No learning progress tracking (classes are live, not self-paced)
- ❌ No bookmarks needed (no recorded content to save)
- ✅ Simple enrollment via IAP packages
- ✅ Transaction history shows which classes user purchased
- ✅ Only 2 collections = simpler, faster, more maintainable

**Result:** Clean, compliant, production-ready database structure! 🎉

## Why This Structure?

1. **GDPR Compliant**: Personal data deleted, financial records anonymized
2. **Apple IAP Ready**: Transaction structure matches Apple's requirements
3. **Scalable**: Easy to query and analyze
4. **Audit-Friendly**: Transaction history preserved for legal compliance
5. **Simple**: Only 2 collections needed (users, transactions) since classes are conducted online
6. **User Privacy**: All personal data removed, but business data retained
7. **RevenueCat Integration**: Subscription status managed by RevenueCat (not Firebase)

---

## 🔄 Subscription Management (RevenueCat)

**⚠️ Important:** Subscription status is **NOT** stored in Firebase.

### Use RevenueCat for Subscription Data:

```dart
// Get RevenueCat provider
final revenueCat = context.read<RevenueCatProvider>();

// Check if user has active subscription
final hasAccess = revenueCat.hasAccess;

// Get subscribed package ID (01, 02, 03)
final subscribedProductId = revenueCat.subscribedProductId;

// Get full customer info
final customerInfo = revenueCat.customerInfo;
final entitlement = customerInfo?.entitlements.active['Rattil Packages'];
final willRenew = entitlement?.willRenew;
final expiryDate = entitlement?.expirationDate;
```

### Why RevenueCat Instead of Firebase?

1. **Single Source of Truth**: RevenueCat manages all subscription logic
2. **Real-time Updates**: Automatic sync with App Store/Play Store
3. **No Sync Issues**: Avoids duplication and inconsistency
4. **Better Performance**: No need to query Firebase for subscription status
5. **Industry Standard**: RevenueCat is designed for subscription management

### What's Stored Where?

| Data Type | Storage Location | Purpose |
|-----------|-----------------|---------|
| **Subscription Status** | RevenueCat | Real-time subscription management |
| **Purchase History** | RevenueCat | Via CustomerInfo.allPurchasedProductIdentifiers |
| **Transaction Records** | Firebase | Legal compliance, analytics, user history |
| **User Profile** | Firebase | Name, email, gender (no subscription data) |
