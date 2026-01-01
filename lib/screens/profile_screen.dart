import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/profile_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/auth_provider.dart' as app_auth;
import 'package:rattil/utils/theme_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rattil/screens/auth/sign_in.dart';
import 'package:rattil/widgets/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final String? userGender;

  const ProfileScreen({
    Key? key,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    this.userGender,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  // General tab controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Password tab controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Avatar color options
  static const List<Color> avatarColors = [
    Color(0xFF14b8a6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFF22C55E), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFFA855F7), // Violet
    Color(0xFFEAB308), // Yellow
    Color(0xFF64748B), // Slate
  ];

  Color _getAvatarColor() {
    // Generate consistent color based on user email
    final hash = widget.userEmail.hashCode.abs();
    return avatarColors[hash % avatarColors.length];
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : ThemeColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch user data from provider if available
    final userProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    _nameController.text = userProvider.userName ?? widget.userName;
    _emailController.text = userProvider.userEmail ?? widget.userEmail;
    // Defer setGender to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileProvider.setGender(widget.userGender);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.setLoading(true);

    try {
      // Update Firestore with merge to handle missing fields
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'gender': profileProvider.selectedGender,
      }, SetOptions(merge: true));

      // Refresh user data in AuthProvider
      await Provider.of<app_auth.AuthProvider>(context, listen: false).fetchUserData();

      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      print('Profile update error: $e');
      _showSnackBar('Failed to update: ${e.toString()}', isError: true);
    }

    profileProvider.setLoading(false);
  }

  Future<void> _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.setPasswordLoading(true);

    try {
      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSnackBar('Password updated successfully!');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to update password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Failed to update password', isError: true);
    }

    profileProvider.setPasswordLoading(false);
  }

  Future<void> _deleteAccount() async {
    final password = _currentPasswordController.text.trim();
    if (password.isEmpty) {
      _showSnackBar('Please enter your password to confirm.', isError: true);
      return;
    }
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.setDeleteLoading(true);
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    try {
      final result = await authProvider.deleteAccount(password: password, context: context);
      if (result == null) {
        _currentPasswordController.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
        // Show snackbar after navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.showError(
            context,
            message: 'Your account has been deleted.',
          );
        });
      } else {
        print('Account deletion error: ' + result.toString());
        _showSnackBar(result, isError: true);
      }
    } catch (e, stack) {
      print('Account deletion exception: ' + e.toString());
      print(stack);
      _showSnackBar('Account deletion failed: ${e.toString()}', isError: true);
    }
    profileProvider.setDeleteLoading(false);
  }

  void _showDeleteAccountDialog() {
    _currentPasswordController.clear(); // Always clear password field when opening dialog
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final dialogBgColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    final accentColor = ThemeColors.primaryTeal;
    final inputBg = isDarkMode ? Color(0xFF374151) : Color(0xFFF3F4F6);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Listener(
          onPointerDown: (_) => FocusScope.of(context).unfocus(),
          child: AlertDialog(
            backgroundColor: dialogBgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Delete Account', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'Are you sure you want to permanently delete your account?',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone. All your profile data will be permanently deleted and your transaction history will be anonymized for legal compliance.',
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'To confirm account deletion, please enter your password below.',
                  style: TextStyle(color: subtextColor, fontSize: 14, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: subtextColor),
                    hintText: 'Enter your password to confirm',
                    hintStyle: TextStyle(color: subtextColor),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _currentPasswordController.clear(); // Clear on cancel
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              child: Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    final accentColor = ThemeColors.primaryTeal;
    final inputBg = isDarkMode ? Color(0xFF374151) : Color(0xFFF3F4F6);
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final isGuest = authProvider.currentUser == null;

    if (isGuest) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: accentColor),
              const SizedBox(height: 16),
              Text('Guest Mode', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text('Sign In / Sign Up to see or change information', style: TextStyle(fontSize: 16, color: subtextColor)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignInScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return Listener(
          onPointerDown: (_) => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: bgColor,
            body: _tabController == null
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : Column(
                    children: [
                      const SizedBox(height: 24),
                        // Profile Avatar and Info
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: _getAvatarColor(),
                                    child: Text(
                                      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(widget.userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 4),
                              Text(widget.userEmail, style: TextStyle(fontSize: 15, color: subtextColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Tab Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController!,
                            indicator: BoxDecoration(
                              gradient: LinearGradient(colors: [ThemeColors.primaryTeal, ThemeColors.primaryTealDark]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: subtextColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'General'),
                              Tab(text: 'Password'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController!,
                            children: [
                              // General Tab
                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _nameController,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your name',
                                        hintStyle: TextStyle(color: subtextColor),
                                        filled: true,
                                        fillColor: inputBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: accentColor, width: 2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _emailController,
                                      enabled: false,
                                      style: TextStyle(color: subtextColor),
                                      decoration: InputDecoration(
                                        hintText: '', // Remove placeholder
                                        hintStyle: TextStyle(color: subtextColor),
                                        filled: true,
                                        fillColor: inputBg.withOpacity(0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => provider.setGender('Male'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                color: provider.selectedGender == 'Male' ? accentColor : inputBg,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Male',
                                                  style: TextStyle(
                                                    color: provider.selectedGender == 'Male' ? Colors.white : textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => provider.setGender('Female'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                color: provider.selectedGender == 'Female' ? accentColor : inputBg,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Female',
                                                  style: TextStyle(
                                                    color: provider.selectedGender == 'Female' ? Colors.white : textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    // Save Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: provider.isLoading ? null : _updateProfile,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF14b8a6)]),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.10),
                                                blurRadius: 10,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (provider.isLoading)
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                )
                                              else
                                                Text(
                                                  'Update Profile',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Delete Account Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: provider.isDeleteLoading ? null : _showDeleteAccountDialog,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.10),
                                                blurRadius: 10,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (provider.isDeleteLoading)
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                )
                                              else
                                                Text(
                                                  'Delete Account',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 55), // Increased padding below Delete Account button
                                    // Add extra padding to avoid overlap with navbar
                                    SizedBox(height: 32),
                                  ],
                                ),
                              ),
                              // Password Tab
                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Current Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _currentPasswordController,
                                      obscureText: true,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Enter current password',
                                        hintStyle: TextStyle(color: subtextColor),
                                        filled: true,
                                        fillColor: inputBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: accentColor, width: 2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('New Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _newPasswordController,
                                      obscureText: true,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Enter new password',
                                        hintStyle: TextStyle(color: subtextColor),
                                        filled: true,
                                        fillColor: inputBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: accentColor, width: 2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Confirm Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: true,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Confirm new password',
                                        hintStyle: TextStyle(color: subtextColor),
                                        filled: true,
                                        fillColor: inputBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: accentColor, width: 2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Update Password Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: provider.isPasswordLoading ? null : _updatePassword,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF14b8a6)]),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.10),
                                                blurRadius: 10,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (provider.isPasswordLoading)
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                )
                                              else
                                                Text(
                                                  'Update Password',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }
}
