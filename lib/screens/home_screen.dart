import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/app_bar_widget.dart';
import 'package:rattil/widgets/hero_card.dart';
import 'package:rattil/widgets/our_packages.dart';
import 'package:rattil/widgets/why_choose_us_section.dart';
import 'package:rattil/widgets/student_reviews_section.dart';
import 'package:rattil/widgets/curved_bottom_bar.dart';
import 'package:rattil/widgets/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool isDarkMode = false;
  bool isDrawerOpen = false;
  final int notificationCount = 2;

  void _onBottomBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Handle navigation between Home, Packages, Profile
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
      isDarkMode = !isDarkMode;
    });
  }

  void _handleNavigation(String route) {
    _closeDrawer();
    Navigator.pushNamed(context, route);
  }

  void _handleLogout() {
    _closeDrawer();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/signin');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          extendBodyBehindAppBar: true,
          backgroundColor: bgColor,
          appBar: AppBarWidget(
            isDarkMode: isDarkMode,
            notificationCount: notificationCount,
            onMenuTap: _toggleDrawer,
            onNotificationTap: () {},
          ),
          body: Padding(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
              bottom: 0,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child: HeroCard(
                      isDarkMode: isDarkMode,
                      onViewPackages: () {
                        // TODO: Navigate to packages screen
                      },
                    ),
                  ),
                  FeaturedCoursesGrid(
                    isDarkMode: isDarkMode,
                    onViewDetails: (pkg) {
                      // TODO: Navigate to package details
                    },
                    onViewMore: () {
                      // TODO: Navigate to all packages
                    },
                  ),
                  const SizedBox(height: 24),
                  WhyChooseUsSection(isDarkMode: isDarkMode),
                  const SizedBox(height: 24),
                  StudentReviewsSection(isDarkMode: isDarkMode),
                ],
              ),
            ),
          ),
        ),
        DrawerMenu(
          isDrawerOpen: isDrawerOpen,
          isDarkMode: isDarkMode,
          closeDrawer: _closeDrawer,
          toggleDarkMode: _toggleDarkMode,
          handleNavigation: _handleNavigation,
          handleLogout: _handleLogout,
          userName: 'Ahmad Hassan',
          userEmail: 'ahmad@example.com',
        ),
        if (!isDrawerOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CurvedBottomBar(
              selectedIndex: _selectedIndex,
              onTap: _onBottomBarTap,
              isDarkMode: isDarkMode,
            ),
          ),
      ],
    );
  }
}
