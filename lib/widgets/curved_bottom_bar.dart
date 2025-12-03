import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/app_colors.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CurvedBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const CurvedBottomBar({Key? key, required this.selectedIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    debugPrint('CurvedBottomBar: selectedIndex=$selectedIndex, isDarkMode=$isDarkMode');
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home, size: 28, color: selectedIndex == 0 ? Colors.white : Colors.teal),
              if (selectedIndex != 0) ...[
                const SizedBox(height: 4),
                Text('Home', style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              ],
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view, size: 28, color: selectedIndex == 1 ? Colors.white : Colors.teal),
              if (selectedIndex != 1) ...[
                const SizedBox(height: 4),
                Text('Packages', style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              ],
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 28, color: selectedIndex == 2 ? Colors.white : Colors.teal),
              if (selectedIndex != 2) ...[
                const SizedBox(height: 4),
                Text('Profile', style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              ],
            ],
          ),
        ],
        onTap: onTap,
      ),
    );
  }
}
