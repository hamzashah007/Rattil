# 📊 Codebase Analysis Report

## 🔍 Unused Files/Features

### ❌ **Completely Unused Files:**

1. **`lib/screens/paywall_screen.dart`**
   - **Status**: ❌ NOT USED ANYWHERE
   - **Reason**: No navigation to this screen found in the codebase
   - **Recommendation**: Remove or implement navigation if needed
   - **Note**: App uses custom package cards instead of RevenueCat Paywall

2. **`lib/screens/privacy_policy_screen.dart`**
   - **Status**: ❌ COMPLETELY COMMENTED OUT
   - **Reason**: Entire file is commented out (all code in `//` comments)
   - **Recommendation**: Delete file or uncomment and implement if needed
   - **Note**: Referenced in `sign_up.dart` but navigation is commented out

3. **`lib/widgets/error_dialog.dart`**
   - **Status**: ❌ EMPTY FILE
   - **Reason**: File exists but is completely empty
   - **Recommendation**: Delete if not needed

### ⚠️ **Partially Used / Mock Data:**

4. **`lib/screens/transaction_history_screen.dart`**
   - **Status**: ⚠️ USED BUT SHOWS MOCK DATA
   - **Usage**: Accessed from Drawer Menu → "Transaction History"
   - **Issue**: Uses hardcoded sample data instead of Firebase
   - **Firebase Helper Available**: `FirestoreHelpers.getUserTransactions()` exists but NOT used
   - **Recommendation**: Connect to Firebase using `FirestoreHelpers.getUserTransactions()`

5. **`lib/screens/notifications_screen.dart`**
   - **Status**: ⚠️ USED BUT SHOWS MOCK DATA
   - **Usage**: Accessed from AppBar notification icon
   - **Issue**: Uses hardcoded sample notifications
   - **Recommendation**: Connect to Firebase or remove if not needed

6. **`lib/utils/firestore_helpers.dart`**
   - **Status**: ⚠️ DEFINED BUT NOT USED
   - **Functions Available**:
     - `createTransaction()` - NOT CALLED anywhere
     - `updateTransactionStatus()` - NOT CALLED anywhere
     - `getUserTransactions()` - NOT CALLED anywhere
     - `updateUserSubscription()` - NOT CALLED anywhere
     - `hasActiveSubscription()` - NOT CALLED anywhere
   - **Recommendation**: Either use these helpers or remove them

### ✅ **Used Files (All Good):**

- ✅ `lib/screens/home_screen.dart` - Main screen
- ✅ `lib/screens/packages_screen.dart` - Package listing
- ✅ `lib/screens/package_detail_screen.dart` - Package details
- ✅ `lib/screens/subscriber_dashboard_screen.dart` - Dashboard
- ✅ `lib/screens/profile_screen.dart` - User profile
- ✅ `lib/screens/auth/sign_in.dart` - Login
- ✅ `lib/screens/auth/sign_up.dart` - Registration
- ✅ `lib/screens/splashscreen.dart` - Splash screen
- ✅ `lib/screens/trial_request_success_screen.dart` - Trial confirmation
- ✅ All widgets are used
- ✅ All providers are used

---

## 🔥 Firebase Data Storage Analysis

### 📁 **Collections in Firebase:**

#### 1. **`users` Collection**
**Location**: `lib/providers/auth_provider.dart`

**Data Stored:**
```dart
{
  'name': String,              // User's full name (required)
  'email': String,             // User's email (required)
  'gender': String?,           // User's gender (OPTIONAL - can be null)
  'uid': String,               // Firebase Auth UID (required)
  'createdAt': Timestamp,      // Account creation timestamp
  'subscriptionStatus': String?, // (Optional - from FirestoreHelpers, but NOT used)
  'currentPackage': String?,   // (Optional - from FirestoreHelpers, but NOT used)
  'lastUpdatedAt': Timestamp?  // (Optional - from FirestoreHelpers, but NOT used)
}
```

**Operations:**
- ✅ **CREATE**: `signUp()` - Creates user document
- ✅ **READ**: `fetchUserData()` - Reads user data
- ✅ **UPDATE**: `_updateProfile()` in `profile_screen.dart` - Updates name and gender
- ✅ **DELETE**: `deleteAccount()` - Deletes user document

**Fields Actually Used:**
- `name` ✅
- `email` ✅
- `gender` ✅ (optional)
- `uid` ✅
- `createdAt` ✅

**Fields NOT Used:**
- `subscriptionStatus` ❌ (defined in FirestoreHelpers but never set)
- `currentPackage` ❌ (defined in FirestoreHelpers but never set)
- `lastUpdatedAt` ❌ (defined in FirestoreHelpers but never set)

---

#### 2. **`transactions` Collection**
**Location**: `lib/utils/firestore_helpers.dart`

**Data Structure (Defined but NOT USED):**
```dart
{
  'transactionId': String,
  'userId': String,
  'userEmail': String,
  'userName': String,
  'appleTransactionId': String,
  'productId': String,
  'packageName': String,
  'subscriptionId': String?,
  'amount': double,
  'currency': String,
  'platform': String,          // 'ios'
  'purchaseDate': Timestamp,
  'expiryDate': DateTime?,
  'status': String,            // 'active', 'cancelled', 'expired', etc.
  'isAnonymized': bool,        // false initially
  'cancelledDate': Timestamp?, // (optional)
  'refundedDate': Timestamp?  // (optional)
}
```

**Operations (ALL DEFINED BUT NOT CALLED):**
- ❌ `createTransaction()` - NOT CALLED anywhere
- ❌ `updateTransactionStatus()` - NOT CALLED anywhere
- ❌ `getUserTransactions()` - NOT CALLED anywhere

**Current Status:**
- ❌ **NO TRANSACTIONS ARE BEING SAVED TO FIREBASE**
- ⚠️ Transaction history screen shows **MOCK DATA** only
- ⚠️ When user deletes account, code tries to anonymize transactions, but since no transactions exist, this does nothing

**Recommendation:**
- Implement transaction saving after successful IAP purchase
- Connect `TransactionHistoryScreen` to Firebase using `getUserTransactions()`

---

### 📊 **Summary of Firebase Usage:**

| Collection | Create | Read | Update | Delete | Status |
|------------|--------|------|--------|--------|--------|
| `users` | ✅ | ✅ | ✅ | ✅ | **ACTIVE** |
| `transactions` | ❌ | ❌ | ❌ | ❌ | **NOT USED** |

---

## 🎯 **Recommendations:**

### **High Priority:**

1. **Remove Unused Files:**
   - Delete `lib/screens/paywall_screen.dart` (or implement navigation)
   - Delete `lib/screens/privacy_policy_screen.dart` (commented out)
   - Delete `lib/widgets/error_dialog.dart` (empty file)

2. **Fix Transaction History:**
   - Implement `FirestoreHelpers.createTransaction()` call after successful IAP purchase
   - Connect `TransactionHistoryScreen` to Firebase
   - Remove mock data

3. **Clean Up FirestoreHelpers:**
   - Either implement all helper functions OR remove unused ones
   - Remove `subscriptionStatus`, `currentPackage`, `lastUpdatedAt` from users collection if not needed (or implement them)

### **Medium Priority:**

4. **Fix Notifications:**
   - Either implement Firebase notifications OR remove the screen
   - Currently shows mock data

5. **Privacy Policy:**
   - Either implement Privacy Policy screen OR remove commented code

### **Low Priority:**

6. **Code Cleanup:**
   - Remove unused imports
   - Remove commented code
   - Clean up unused variables

---

## 📝 **Current Firebase Data Flow:**

### **What's Actually Stored:**
1. **User Registration** → Creates `users/{uid}` with: name, email, gender (optional), uid, createdAt
2. **Profile Update** → Updates `users/{uid}` with: name, gender
3. **Account Deletion** → Deletes `users/{uid}` and anonymizes `transactions` (but no transactions exist)

### **What's NOT Stored (But Should Be):**
1. ❌ IAP Purchase Transactions
2. ❌ Subscription Status
3. ❌ Current Package
4. ❌ Transaction History

---

## ✅ **Action Items:**

- [ ] Delete unused files (`paywall_screen.dart`, `privacy_policy_screen.dart`, `error_dialog.dart`)
- [ ] Implement transaction saving after IAP purchase
- [ ] Connect TransactionHistoryScreen to Firebase
- [ ] Fix or remove NotificationsScreen mock data
- [ ] Clean up FirestoreHelpers (use or remove)
- [ ] Remove unused fields from users collection OR implement them

