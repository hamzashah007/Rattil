# Apple App Store Compliance Fixes

## Rejection Issues & Solutions

### ✅ Issue 1: Screenshots (Guideline 2.3.3)
**Problem:** iPad screenshots show stretched iPhone images.

**Solution:**
- Take NEW iPad screenshots on an actual iPad device or iPad simulator
- Do NOT stretch iPhone screenshots to fit iPad dimensions
- Ensure screenshots show the app in use on the correct device

**Action Required:** 
Upload new iPad screenshots in App Store Connect.

---

### ✅ Issue 2: Forced Registration (Guideline 5.1.1)
**Problem:** App required users to sign in before accessing packages and making purchases.

**Solution:** 
- Modified `splashscreen.dart` to allow guest access
- App now goes directly to HomeScreen for all users
- Users can browse packages and make purchases without signing in
- Sign-in is optional and available through the app menu

**Files Modified:**
- `/lib/screens/splashscreen.dart` - Removed authentication check, now allows guest access

---

### ✅ Issue 3: Restore Purchases Button (Guideline 3.1.1)
**Problem:** "Restore Purchases" button was not prominent enough (was at bottom of list).

**Solution:**
- Added a PROMINENT "Restore Purchases" button at the TOP of the packages list
- Button is styled as an outlined button with icon and clear text
- Button is easily visible and accessible before any packages
- Still kept the legal links at the bottom

**Files Modified:**
- `/lib/screens/packages_screen.dart` - Added prominent restore button at index 0 of package list

**Button Features:**
- Large, full-width outlined button
- Teal color matching app theme
- Restore icon
- Loading indicator when restoring
- Positioned at the very top of the packages list (first item)

---

### ✅ Issue 4: EULA Link (Guideline 3.1.2)
**Problem:** EULA link missing from App Store Connect metadata.

**Solution:**
The EULA link is already present in the app:
- Terms of Use: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Privacy Policy: `https://docs.google.com/document/d/1mzfze5c8wibnWrzIAR3bHWwKkA0o_tIzkKsXaoFxflM/edit?pli=1&tab=t.0`

**Action Required in App Store Connect:**
1. Go to App Store Connect → Your App → App Information
2. In the "App Description" field, add this text at the end:

```
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://docs.google.com/document/d/1mzfze5c8wibnWrzIAR3bHWwKkA0o_tIzkKsXaoFxflM/edit?pli=1&tab=t.0
```

OR

3. Add the EULA in the dedicated EULA field if you want to use a custom EULA
4. Save changes

---

## Summary of Code Changes

### 1. Guest Access Enabled
**Before:**
```dart
void _navigateBasedOnAuthState() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
  } else {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
  }
}
```

**After:**
```dart
void _navigateBasedOnAuthState() {
  // Allow guest access - always go to HomeScreen
  // User can sign in from the app menu if they want
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
}
```

### 2. Prominent Restore Purchases Button Added
- Button now appears as the FIRST item in the packages list
- Styled as a large outlined button with icon
- Clearly labeled "Restore Purchases"
- Includes loading state indicator
- Full-width for maximum visibility

---

## Testing Checklist

Before resubmitting to Apple, test:

1. **Guest Access:**
   - [ ] App opens without requiring sign-in
   - [ ] Can view all packages without authentication
   - [ ] Can attempt to purchase without signing in first
   - [ ] Sign-in is optional and accessible from menu

2. **Restore Purchases Button:**
   - [ ] Button is visible at the TOP of packages list
   - [ ] Button is large and clearly labeled
   - [ ] Tapping button restores previous purchases
   - [ ] Loading indicator shows during restore
   - [ ] Success/failure messages display correctly

3. **Legal Links:**
   - [ ] Terms of Use link works and opens Apple EULA
   - [ ] Privacy Policy link works and opens your policy
   - [ ] Both links are visible in the app
   - [ ] Links added to App Store Connect description

4. **iPad Screenshots:**
   - [ ] Take new screenshots on iPad
   - [ ] Upload to App Store Connect
   - [ ] Verify they look correct in all required sizes

---

## App Store Connect Updates Required

1. **App Description:** Add EULA and Privacy Policy links
2. **iPad Screenshots:** Upload new, non-stretched iPad screenshots
3. **Version Notes:** Mention "Guest access enabled" and "Improved restore purchases visibility"

---

## Ready for Resubmission

All code issues are fixed. Complete these final steps:

1. ✅ Code changes implemented
2. ⏳ Update App Store Connect description with EULA link
3. ⏳ Upload new iPad screenshots
4. ⏳ Test on real device
5. ⏳ Submit new build

**Good luck with your resubmission! 🚀**
