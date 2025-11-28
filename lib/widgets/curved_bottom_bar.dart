import 'package:flutter/material.dart';
import 'package:rattil/utils/app_colors.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CurvedBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isDarkMode;
  const CurvedBottomBar({Key? key, required this.selectedIndex, required this.onTap, this.isDarkMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      elevation: 0,
      child: CurvedNavigationBar(
        index: selectedIndex,
        height: 72, // Increased height for more prominent curved bar
        backgroundColor: Colors.transparent,
        color: isDarkMode ? ThemeColors.darkCard : AppColors.white,
        buttonBackgroundColor: AppColors.teal500,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        items: [
          Icon(Icons.home, size: 28, color: selectedIndex == 0 ? Colors.white : Colors.teal),
          Icon(Icons.grid_view, size: 28, color: selectedIndex == 1 ? Colors.white : Colors.teal),
          Icon(Icons.person, size: 28, color: selectedIndex == 2 ? Colors.white : Colors.teal),
        ],
        onTap: onTap,
      ),
    );
  }
}
