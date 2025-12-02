import 'package:flutter/material.dart';
import 'package:rattil/utils/constants.dart';
import 'package:rattil/utils/theme_colors.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;

  const ProfileScreen({
    Key? key,
    required this.isDarkMode,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
  
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? selectedGender;
  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = widget.isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg; // Use same bg for cards
    final textColor = widget.isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = widget.isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    final accentColor = ThemeColors.primaryTeal;
 

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
           
            const SizedBox(height: 12),
            // Profile Avatar and Info
            Center(
              child: Column(
                children: [
                  widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty
                      ? CircleAvatar(radius: 36, backgroundImage: NetworkImage(widget.userAvatarUrl!))
                      : CircleAvatar(radius: 36, backgroundColor: accentColor, child: Text(widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  Text(widget.userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(widget.userEmail, style: TextStyle(fontSize: 15, color: subtextColor)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Profile Form
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            // Gender Options
         Row(
  children: [
    Expanded(
      child: RadioListTile<String>(
        value: 'Male',
        groupValue: selectedGender,
        onChanged: (val) {
          setState(() {
            selectedGender = val;
          });
        },
        title: Text('Male', style: TextStyle(color: textColor)),
        activeColor: accentColor,
      ),
    ),
    Expanded(
      child: RadioListTile<String>(
        value: 'Female',
        groupValue: selectedGender,
        onChanged: (val) {
          setState(() {
            selectedGender = val;
          });
        },
        title: Text('Female', style: TextStyle(color: textColor)),
        activeColor: accentColor,
      ),
    ),
  ],
),
            const SizedBox(height: 24),
            // Save Button
            SizedBox(
  width: double.infinity,
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {},
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
          Text(
            'Save',
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
    );
  }

  Widget _buildProfileAction(IconData icon, String label, Color iconColor, Color textColor, {String? subtext}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, color: textColor)),
                  if (subtext != null)
                    Text(subtext, style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
