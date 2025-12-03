import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/theme_colors.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final int notificationCount;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  const AppBarWidget({
    Key? key,
    required this.notificationCount,
    required this.onMenuTap,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(64); // Reverted to default height

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    return Material(
      color: bgColor,
      elevation: 2,
      child: Container(
        height: 64 + MediaQuery.of(context).padding.top, // Adjust height for status bar
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 20,
          right: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rattil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_none, color: textColor, size: 24),
                      onPressed: onNotificationTap,
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: ThemeColors.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.menu, color: textColor, size: 24),
                  onPressed: onMenuTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
