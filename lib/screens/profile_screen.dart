import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/profile_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/auth_provider.dart' as app_auth;
import 'package:rattil/utils/theme_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _selectedGender;
  
  // Password tab controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordLoading = false;

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
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _selectedGender = widget.userGender;
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

    setState(() => _isLoading = true);

    try {
      // Update Firestore with merge to handle missing fields
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
      }, SetOptions(merge: true));

      // Refresh user data in AuthProvider
      await Provider.of<app_auth.AuthProvider>(context, listen: false).fetchUserData();

      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      print('Profile update error: $e');
      _showSnackBar('Failed to update: ${e.toString()}', isError: true);
    }

    setState(() => _isLoading = false);
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

    setState(() => _isPasswordLoading = true);

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

    setState(() => _isPasswordLoading = false);
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

    return ChangeNotifierProvider<ProfileProvider>(
      create: (_) => ProfileProvider(),
      child: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          return Scaffold(
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
                                hintText: 'Email cannot be changed',
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
                                    onTap: () => setState(() => _selectedGender = 'Male'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Male' ? accentColor : inputBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Male',
                                          style: TextStyle(
                                            color: _selectedGender == 'Male' ? Colors.white : textColor,
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
                                    onTap: () => setState(() => _selectedGender = 'Female'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Female' ? accentColor : inputBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Female',
                                          style: TextStyle(
                                            color: _selectedGender == 'Female' ? Colors.white : textColor,
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
                                onTap: _isLoading ? null : _updateProfile,
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
                                      if (_isLoading)
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
                            const SizedBox(height: 32),
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
                                onTap: _isPasswordLoading ? null : _updatePassword,
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
                                      if (_isPasswordLoading)
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
          );
        },
      ),
    );
  }
}
