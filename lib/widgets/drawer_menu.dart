import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';

class DrawerMenu extends StatelessWidget {
  final VoidCallback closeDrawer;
  final VoidCallback toggleDarkMode;
  final Function(String route) handleNavigation;
  final VoidCallback handleLogout;
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;

  const DrawerMenu({
    Key? key,
    required this.closeDrawer,
    required this.toggleDarkMode,
    required this.handleNavigation,
    required this.handleLogout,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final drawerProvider = Provider.of<DrawerProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isDrawerOpen = drawerProvider.isDrawerOpen;
    
    debugPrint('DrawerMenu: isDrawerOpen=$isDrawerOpen, isDarkMode=$isDarkMode');
    final drawerBg = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final hoverBg = isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final avatarGradientStart = const Color(0xFF2dd4bf);
    final avatarGradientEnd = const Color(0xFF0d9488);
    final toggleOnColor = const Color(0xFF0d9488);
    final logoutColor = const Color(0xFFef4444);
    final overlayColor = Colors.black.withOpacity(0.5);

    return Stack(
      children: [
        // Overlay
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isDrawerOpen ? 0.5 : 0.0,
          child: isDrawerOpen
              ? GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    closeDrawer();
                  },
                  child: Container(
                    color: overlayColor,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Drawer Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          right: isDrawerOpen ? 0 : -320,
          top: 0,
          bottom: 0,
          child: Container(
            width: 270,
            height: double.infinity,
            color: drawerBg,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      padding: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 32,
                                  backgroundImage: NetworkImage(userAvatarUrl!),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [avatarGradientStart, avatarGradientEnd],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: subtextColor,
                                    decoration: TextDecoration.none,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu Items
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      text: 'Transaction History',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        handleNavigation('/transactions');
                      },
                      textColor: textColor,
                      hoverBg: hoverBg,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.star_rate,
                      text: 'Rate our App',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        handleNavigation('/rate');
                      },
                      textColor: textColor,
                      hoverBg: hoverBg,
                    ),
                    // Replace custom dark mode toggle with Switch
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: toggleDarkMode,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                        color: textColor,
                                        size: 20,
                                        semanticLabel: 'Dark Theme',
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          'Dark Theme',
                                          style: TextStyle(color: textColor, fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isDarkMode,
                                  onChanged: (val) => toggleDarkMode(),
                                  activeColor: isDarkMode ? toggleOnColor : Colors.teal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 0),
                      child: Divider(
                        color: borderColor,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      text: 'Logout',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        handleLogout();
                      },
                      textColor: logoutColor,
                      hoverBg: hoverBg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Color textColor,
    required Color hoverBg,
  }) {
    final isLogout = text.toLowerCase() == 'logout';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 20, semanticLabel: text),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
