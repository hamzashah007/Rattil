import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/home_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';
import 'package:rattil/providers/auth_provider.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/app_bar_widget.dart';
import 'package:rattil/widgets/quran_carousel.dart';
import 'package:rattil/widgets/our_packages.dart';
import 'package:rattil/widgets/why_choose_us_section.dart';
import 'package:rattil/widgets/curved_bottom_bar.dart';
import 'package:rattil/widgets/drawer_menu.dart';
import 'package:rattil/screens/packages_screen.dart';
import 'package:rattil/screens/profile_screen.dart';
import 'package:rattil/screens/package_detail_screen.dart';
import 'package:rattil/screens/transaction_history_screen.dart';
import 'package:rattil/screens/notifications_screen.dart';
import 'package:rattil/screens/auth/sign_in.dart';
import 'package:rattil/providers/revenuecat_provider.dart';

// Method channel for moving app to background
const platform = MethodChannel('com.rattil.app/background');

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int notificationCount = 2;

  @override
  void initState() {
    super.initState();
    // Fetch user data when HomeScreen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserData();
    });
  }

  void _onBottomBarTap(BuildContext context, int index) {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    if (provider.selectedIndex == index) return;
    provider.setSelectedIndex(index);
  }

  void _goToPackagesTab(BuildContext context) {
    Provider.of<HomeProvider>(context, listen: false).setSelectedIndex(1);
  }

  Widget _getScreenContent(BuildContext context, int selectedIndex) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (selectedIndex == 0) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuranCarousel(
              imageUrls: [
                'https://your-image-url-1.jpg',
                'https://your-image-url-2.jpg',
                'https://your-image-url-3.jpg',
              ],
              height: 180,
            ),
            OurPackage(
              onViewDetails: (pkg) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PackageDetailScreen(package: pkg),
                  ),
                );
              },
              onViewMore: () => _goToPackagesTab(context),
            ),
            WhyChooseUsSection(),
            const SizedBox(height: 24),
          ],
        ),
      );
    } else if (selectedIndex == 1) {
      return PackagesScreen(showAppBar: false);
    } else {
      return ProfileScreen(
        userName: authProvider.userName ?? 'User',
        userEmail: authProvider.userEmail ?? '',
        userGender: authProvider.userGender,
      );
    }
  }

  void _toggleDrawer(BuildContext context) {
    final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
    drawerProvider.setDrawerOpen(!drawerProvider.isDrawerOpen);
  }

  void _closeDrawer(BuildContext context) {
    Provider.of<DrawerProvider>(context, listen: false).closeDrawer();
  }

  void _toggleDarkMode(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleDarkMode();
  }

  void _handleNavigation(BuildContext context, String route) {
    _closeDrawer(context);
    if (route == '/transactions') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionHistoryScreen(),
        ),
      );
    } else if (route == '/rate') {
      // Example: open rate screen
    } else {
      // Add other direct navigation cases here if needed
    }
  }

  void _handleLogout(BuildContext context) {
    _closeDrawer(context);
    
    // Use Future.delayed to ensure drawer is closed before showing dialog
    Future.delayed(Duration(milliseconds: 350), () {
      final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      final bgColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
      final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
      final subtitleColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
      
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Logout', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to logout?', style: TextStyle(color: subtitleColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: ThemeColors.primaryTeal)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Provider.of<AuthProvider>(context, listen: false).signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeProvider>(
      create: (_) => HomeProvider(),
      child: Consumer4<HomeProvider, ThemeProvider, DrawerProvider, AuthProvider>(
        builder: (context, homeProvider, themeProvider, drawerProvider, authProvider, _) {
          final isDarkMode = themeProvider.isDarkMode;
          final isDrawerOpen = drawerProvider.isDrawerOpen;
          final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              
              // If drawer is open, close it first
              if (isDrawerOpen) {
                drawerProvider.closeDrawer();
                return;
              }
              
              // If not on home tab, go to home tab first
              if (homeProvider.selectedIndex != 0) {
                homeProvider.setSelectedIndex(0);
                return;
              }
              
              // Move app to background
              try {
                await platform.invokeMethod('moveToBackground');
              } catch (e) {
                // Fallback: minimize using system navigator
                SystemNavigator.pop();
              }
            },
            child: Stack(
              children: [
                Scaffold(
                  key: _scaffoldKey,
                  extendBodyBehindAppBar: true,
                  backgroundColor: bgColor,
                  appBar: AppBarWidget(
                    notificationCount: notificationCount,
                    onMenuTap: () => _toggleDrawer(context),
                    onNotificationTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()),
                      );
                    },
                  ),
                body: Padding(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight + MediaQuery.of(context).padding.top,
                    bottom: 0,
                  ),
                  child: _getScreenContent(context, homeProvider.selectedIndex),
                ),
              ),
              DrawerMenu(
                closeDrawer: () => _closeDrawer(context),
                toggleDarkMode: () => _toggleDarkMode(context),
                handleNavigation: (route) => _handleNavigation(context, route),
                handleLogout: () => _handleLogout(context),
                onProfileTap: () {
                  // Navigate to profile tab after drawer closes
                  Future.delayed(Duration(milliseconds: 350), () {
                    homeProvider.setSelectedIndex(2);
                  });
                },
                onCustomerCenterTap: () {
                  Provider.of<RevenueCatProvider>(context, listen: false).openCustomerCenter();
                },
                userName: authProvider.userName ?? 'User',
                userEmail: authProvider.userEmail ?? '',
              ),
              if (!isDrawerOpen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CurvedBottomBar(
                    selectedIndex: homeProvider.selectedIndex,
                    onTap: (index) => _onBottomBarTap(context, index),
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
