# User Mode vs Guest Mode - Subscription & Identification Explanation

## Current Implementation Status

### How RevenueCat Works
RevenueCat uses **device-based subscriptions** tied to the Apple ID (App Store account), NOT Firebase user accounts. This is Apple's standard IAP behavior.

---

## Your Questions Answered

### 1️⃣ **If User mode subscribes, can Guest mode access on same device?**

**YES** ✅ - Currently, subscriptions are **device-based**, meaning:
- If a logged-in user subscribes on a device
- Then logs out and uses Guest mode on **the same device**
- Guest mode will ALSO have access to the subscription

**Why?**
- RevenueCat checks the Apple ID (device's App Store account)
- Both User mode and Guest mode use the SAME Apple ID on the same device
- Apple's IAP is tied to the Apple ID, not your app's user account

**Current Code Evidence:**
```dart
// In revenuecat_provider.dart - start() method
// RevenueCat initializes WITHOUT linking to Firebase user
Future<void> start() async {
  if (_started) return;
  _started = true;
  await _refreshAll(); // Gets subscription from Apple ID
  Purchases.addCustomerInfoUpdateListener(_customerInfoListener);
}
```

---

### 2️⃣ **How to identify which user subscribed: Guest or User?**

**PROBLEM** ❌: Currently, you CANNOT identify if Guest or User subscribed because:
- RevenueCat is NOT linked to Firebase Authentication
- No call to `Purchases.logIn(firebaseUserId)` exists in your code
- Subscriptions are anonymous (tied only to Apple ID)

**SOLUTION** ✅: You need to implement **RevenueCat User Identification**:

#### Recommended Implementation:

```dart
// In revenuecat_provider.dart
Future<void> linkToFirebaseUser(String firebaseUserId) async {
  try {
    debugPrint('🔗 [RevenueCat] Linking to Firebase user: $firebaseUserId');
    await Purchases.logIn(firebaseUserId);
    await refreshCustomerInfo();
    debugPrint('✅ [RevenueCat] Successfully linked to Firebase user');
  } catch (e) {
    debugPrint('❌ [RevenueCat] Error linking user: $e');
  }
}

Future<void> unlinkFromFirebaseUser() async {
  try {
    debugPrint('🔗 [RevenueCat] Unlinking from Firebase user (switching to anonymous)');
    await Purchases.logOut();
    await refreshCustomerInfo();
    debugPrint('✅ [RevenueCat] Successfully unlinked from Firebase user');
  } catch (e) {
    debugPrint('❌ [RevenueCat] Error unlinking user: $e');
  }
}
```

#### Call these methods:

**When User Signs In:**
```dart
// In sign_in.dart or auth_provider.dart
final revenueCat = context.read<RevenueCatProvider>();
await revenueCat.linkToFirebaseUser(user.uid);
```

**When User Logs Out (switches to Guest):**
```dart
// In logout flow
final revenueCat = context.read<RevenueCatProvider>();
await revenueCat.unlinkFromFirebaseUser();
```

**Benefits:**
- RevenueCat will track which Firebase user subscribed
- You can see subscription history per user in RevenueCat dashboard
- Subscriptions transfer across devices when user logs in

---

### 3️⃣ **How to add Guest mode person to Zoom or outside app classes?**

**PROBLEM** ❌: Guest mode users have NO identity:
- No email
- No name
- No Firebase UID
- Anonymous device-based subscription only

**SOLUTION OPTIONS:**

#### Option A: Force Email Collection for Subscribers (Recommended)
When a Guest subscribes, show a dialog:
```dart
// After successful subscription in Guest mode
if (authProvider.isGuest && hasAccess) {
  showDialog(
    context: context,
    barrierDismissible: false, // Must provide email
    builder: (context) => AlertDialog(
      title: Text('Welcome to Rattil Premium!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('To join Zoom classes, please provide your email:'),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            decoration: InputDecoration(
              labelText: 'Name (Optional)',
              hintText: 'Your Name',
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // Save to Firestore with subscription details
            await FirebaseFirestore.instance.collection('subscribers').add({
              'email': emailController.text,
              'name': nameController.text,
              'mode': 'guest',
              'deviceId': await _getDeviceId(), // Use device_info_plus
              'productId': subscribedProductId,
              'subscribedAt': FieldValue.serverTimestamp(),
            });
            Navigator.pop(context);
          },
          child: Text('Continue'),
        ),
      ],
    ),
  );
}
```

#### Option B: Encourage Sign Up
```dart
// Show banner in Dashboard for Guest subscribers
if (authProvider.isGuest && hasAccess) {
  return Container(
    padding: EdgeInsets.all(16),
    color: Colors.orange.shade100,
    child: Column(
      children: [
        Icon(Icons.info_outline, color: Colors.orange.shade700),
        SizedBox(height: 8),
        Text(
          'Sign up to unlock full features!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('Join Zoom classes, sync across devices, and more.'),
        ElevatedButton(
          onPressed: () {
            // Navigate to sign up with pre-filled subscription
            Navigator.push(context, SignUpScreen(hasSubscription: true));
          },
          child: Text('Create Account'),
        ),
      ],
    ),
  );
}
```

#### Option C: Store Device Info + Subscription
For Guest subscribers, store minimal info:
```dart
// After successful subscription in Guest mode
if (authProvider.isGuest && info != null) {
  final deviceInfo = await DeviceInfoPlugin();
  final deviceId = Platform.isIOS 
    ? (await deviceInfo.iosInfo).identifierForVendor 
    : (await deviceInfo.androidInfo).id;
  
  await FirebaseFirestore.instance.collection('guest_subscribers').add({
    'deviceId': deviceId,
    'productId': subscribedProductId,
    'subscribedAt': FieldValue.serverTimestamp(),
    'platform': Platform.isIOS ? 'ios' : 'android',
    // No email - they must contact support or sign up for Zoom
  });
}
```

Then show a message:
```
"To join Zoom classes, please email us at support@rattil.com with your device ID: $deviceId"
```

---

## Recommended Complete Flow

### User Mode (Logged In):
1. User signs in with Firebase
2. Call `revenueCat.linkToFirebaseUser(user.uid)`
3. User subscribes
4. RevenueCat links subscription to Firebase UID
5. Store subscriber info in Firestore:
   ```dart
   await FirebaseFirestore.instance.collection('subscribers').doc(user.uid).set({
     'email': user.email,
     'name': user.displayName,
     'productId': subscribedProductId,
     'subscribedAt': FieldValue.serverTimestamp(),
     'revenueCatUserId': user.uid,
   });
   ```
6. Use email to add to Zoom meeting
7. Subscription syncs across devices when user logs in

### Guest Mode:
1. User uses app as Guest (anonymous)
2. Call `revenueCat.unlinkFromFirebaseUser()` (anonymous mode)
3. Guest subscribes (device-based)
4. **FORCE email collection** or show "Sign up to join classes" banner
5. If email provided, store in Firestore:
   ```dart
   await FirebaseFirestore.instance.collection('guest_subscribers').add({
     'email': guestEmail,
     'deviceId': deviceId,
     'productId': subscribedProductId,
     'subscribedAt': FieldValue.serverTimestamp(),
   });
   ```
6. Use email to add to Zoom meeting
7. Subscription does NOT sync to other devices (tied to Apple ID on this device)

---

## Best Practice Recommendation

**Apple App Store Guidelines Compliance:**
1. ✅ Allow Guest mode (no forced sign-in)
2. ✅ Restore Purchases button (implemented)
3. ⚠️ For features requiring identity (Zoom classes), request email AFTER subscription
4. ✅ Show benefits of creating account (sync, Zoom access, etc.)

**Implementation Priority:**
1. **HIGH**: Implement `Purchases.logIn()` and `Purchases.logOut()` for User mode
2. **HIGH**: Collect email from Guest subscribers for Zoom access
3. **MEDIUM**: Show "Sign up" banner for Guest subscribers
4. **MEDIUM**: Store subscriber info in Firestore for both modes

---

## Code Changes Needed

### 1. Add to `revenuecat_provider.dart`:
```dart
Future<void> linkToFirebaseUser(String firebaseUserId) async {
  try {
    debugPrint('🔗 [RevenueCat] Linking to Firebase user: $firebaseUserId');
    await Purchases.logIn(firebaseUserId);
    await refreshCustomerInfo();
    debugPrint('✅ [RevenueCat] Successfully linked to Firebase user');
  } catch (e) {
    debugPrint('❌ [RevenueCat] Error linking user: $e');
  }
}

Future<void> unlinkFromFirebaseUser() async {
  try {
    debugPrint('🔗 [RevenueCat] Unlinking from Firebase user (guest mode)');
    await Purchases.logOut();
    await refreshCustomerInfo();
    debugPrint('✅ [RevenueCat] Successfully unlinked');
  } catch (e) {
    debugPrint('❌ [RevenueCat] Error unlinking: $e');
  }
}
```

### 2. Call in `auth_provider.dart`:
```dart
// After sign in
Future<void> signIn(String email, String password) async {
  // ...existing sign in code...
  final revenueCat = // get RevenueCatProvider instance
  await revenueCat.linkToFirebaseUser(currentUser!.uid);
}

// On logout
Future<void> signOut() async {
  final revenueCat = // get RevenueCatProvider instance
  await revenueCat.unlinkFromFirebaseUser();
  // ...existing logout code...
}
```

### 3. Add email collection dialog after Guest subscription
### 4. Store subscriber data in Firestore for Zoom invitations

---

## Summary

| Feature | User Mode | Guest Mode (Current) | Guest Mode (Recommended) |
|---------|-----------|---------------------|-------------------------|
| **Identification** | Firebase UID + Email | None (anonymous) | Device ID + Email (collected) |
| **Subscription Sync** | ✅ Across devices | ❌ Device-only | ❌ Device-only |
| **Zoom Access** | ✅ Via email | ❌ No email | ✅ Via collected email |
| **RevenueCat Tracking** | ✅ Per user | ❌ Anonymous | ⚠️ Per device |
| **Restore Purchases** | ✅ All devices | ✅ Same device | ✅ Same device |

**Key Insight:** RevenueCat + Apple IAP are device-based by default. You MUST implement `Purchases.logIn()` to link subscriptions to Firebase users for proper tracking and cross-device sync.
