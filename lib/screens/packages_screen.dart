import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/packages_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';
import 'package:rattil/utils/constants.dart';
import 'package:rattil/widgets/package_card.dart';
import 'package:rattil/widgets/app_bar_widget.dart';
import 'package:rattil/widgets/curved_bottom_bar.dart';
import 'package:rattil/widgets/drawer_menu.dart';
import 'package:rattil/screens/profile_screen.dart';
import 'package:rattil/screens/enroll_now_screen.dart';

class PackagesScreen extends StatefulWidget {
  final bool showAppBar;
  const PackagesScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int notificationCount = 2;
  final String userName = 'John Doe';
  final String userEmail = 'john@example.com';
  final String? userAvatarUrl = null;

  void _onBottomBarTap(BuildContext context, int index) {
    final provider = Provider.of<PackagesProvider>(context, listen: false);
    if (provider.selectedIndex == index) return;
    if (index == 0 && Navigator.of(context).canPop()) {
      debugPrint('PackagesScreen: Home icon tapped, popping to HomeScreen');
      Navigator.pop(context);
      return;
    }
    provider.setSelectedIndex(index);
  }

  void _toggleDrawer(BuildContext context) {
    final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
    drawerProvider.setDrawerOpen(!drawerProvider.isDrawerOpen);
  }

  void _closeDrawer(BuildContext context) {
    Provider.of<DrawerProvider>(context, listen: false).closeDrawer();
  }

  void _toggleDarkMode(BuildContext context) {
    Provider.of<ThemeProvider>(context, listen: false).toggleDarkMode();
  }

  void _handleNavigation(BuildContext context, String route) {
    _closeDrawer(context);
  }

  void _handleLogout(BuildContext context) {
    _closeDrawer(context);
  }

  List<Package> get filteredPackages {
    return packages;
  }

  Widget _getScreenContent(BuildContext context) {
    final provider = Provider.of<PackagesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    debugPrint('PackagesScreen: Showing tab index: ${provider.selectedIndex}');
    if (provider.selectedIndex == 0) {
      return Center(child: Text('Home Screen', style: TextStyle(fontSize: 32)));
    } else if (provider.selectedIndex == 1) {
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
                  color: isDarkMode ? AppConstants.textColorDark : AppConstants.textColor,
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
                  onEnroll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EnrollNowScreen(package: pkg),
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
        userName: userName,
        userEmail: userEmail,
        userAvatarUrl: userAvatarUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PackagesProvider>(
      create: (_) => PackagesProvider(),
      child: Consumer3<PackagesProvider, ThemeProvider, DrawerProvider>(
        builder: (context, provider, themeProvider, drawerProvider, _) {
          final isDarkMode = themeProvider.isDarkMode;
          final isDrawerOpen = drawerProvider.isDrawerOpen;
          
          return Stack(
            children: [
              Scaffold(
                key: _scaffoldKey,
                backgroundColor: isDarkMode ? AppConstants.bgColorDark : AppConstants.bgColor,
                appBar: widget.showAppBar
                    ? PreferredSize(
                        preferredSize: Size.fromHeight(kToolbarHeight),
                        child: AppBarWidget(
                          notificationCount: notificationCount,
                          onMenuTap: () => _toggleDrawer(context),
                          onNotificationTap: () {},
                        ),
                      )
                    : null,
                body: _getScreenContent(context),
              ),
              DrawerMenu(
                closeDrawer: () => _closeDrawer(context),
                toggleDarkMode: () => _toggleDarkMode(context),
                handleNavigation: (route) => _handleNavigation(context, route),
                handleLogout: () => _handleLogout(context),
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
                    selectedIndex: provider.selectedIndex,
                    onTap: (index) => _onBottomBarTap(context, index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
