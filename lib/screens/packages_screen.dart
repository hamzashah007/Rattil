import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/utils/constants.dart';
import 'package:rattil/widgets/package_card.dart';
import 'package:rattil/widgets/app_bar_widget.dart';
import 'package:rattil/widgets/curved_bottom_bar.dart';

import 'package:rattil/widgets/drawer_menu.dart';
import 'package:rattil/screens/profile_screen.dart';
import 'package:rattil/screens/enroll_now_screen.dart';


class PackagesScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isDarkMode;
  const PackagesScreen({Key? key, this.showAppBar = true, required this.isDarkMode}) : super(key: key);

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool isDrawerOpen = false;
  final int notificationCount = 2;
  final String userName = 'John Doe'; // Replace with actual user data
  final String userEmail = 'john@example.com'; // Replace with actual user data
  final String? userAvatarUrl = null; // Replace with actual user data

  void _onBottomBarTap(int index) {
    if (_selectedIndex == index) return;
    if (index == 0 && Navigator.of(context).canPop()) {
      debugPrint('PackagesScreen: Home icon tapped, popping to HomeScreen');
      Navigator.pop(context);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    // Only update selectedIndex, do not navigate to a new screen
    // CurvedNavigationBar will handle its own animation
  }

  void _toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
    });
  }

  void _closeDrawer() {
    setState(() {
      isDrawerOpen = false;
    });
  }

  void _toggleDarkMode() {
    setState(() {
      // isDarkMode = !isDarkMode;
    });
  }

  void _handleNavigation(String route) {
    _closeDrawer();
    // Implement navigation logic here
  }

  void _handleLogout() {
    _closeDrawer();
    // Implement logout logic here
  }

  List<Package> get filteredPackages {
    return packages;
  }

  Widget _getScreenContent() {
    debugPrint('PackagesScreen: Showing tab index: $_selectedIndex');
    if (_selectedIndex == 0) {
      return Center(child: Text('Home Screen', style: TextStyle(fontSize: 32)));
    } else if (_selectedIndex == 1) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Our Packages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? AppConstants.textColorDark : AppConstants.textColor,
                  letterSpacing: -1,
                  wordSpacing: 0,
                ),
              ),
              
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 75),
              itemCount: filteredPackages.length,
              itemBuilder: (context, index) {
                final pkg = filteredPackages[index];
                return PackageCard(
                  package: pkg,
                  delay: index * 100,
                  isDarkMode: widget.isDarkMode,
                  // Add navigation callback
                  onEnroll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EnrollNowScreen(isDarkMode: widget.isDarkMode, package: pkg),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      return ProfileScreen(
        isDarkMode: widget.isDarkMode,
        userName: userName,
        userEmail: userEmail,
        userAvatarUrl: userAvatarUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: widget.isDarkMode ? AppConstants.bgColorDark : AppConstants.bgColor,
          appBar: widget.showAppBar
              ? PreferredSize(
                  preferredSize: Size.fromHeight(kToolbarHeight),
                  child: AppBarWidget(
                    isDarkMode: widget.isDarkMode,
                    notificationCount: notificationCount,
                    onMenuTap: _toggleDrawer,
                    onNotificationTap: () {},
                  ),
                )
              : null,
          body: _getScreenContent(),
        ),
        DrawerMenu(
          isDrawerOpen: isDrawerOpen,
          isDarkMode: widget.isDarkMode,
          closeDrawer: _closeDrawer,
          toggleDarkMode: _toggleDarkMode,
          handleNavigation: _handleNavigation,
          handleLogout: _handleLogout,
          userName: userName,
          userEmail: userEmail,
          userAvatarUrl: userAvatarUrl,
        ),
        if (!isDrawerOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CurvedBottomBar(
              selectedIndex: _selectedIndex,
              onTap: _onBottomBarTap,
              isDarkMode: widget.isDarkMode,
            ),
          ),
      ],
    );
  }
}
