import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/auth_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';
import 'package:rattil/providers/notification_provider.dart';
import 'package:rattil/providers/profile_provider.dart';
import 'package:rattil/providers/revenuecat_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/screens/splashscreen.dart';

import 'firebase_options.dart';

const _revenuecatApiKeyIOS = 'appl_pMSdZUXXAVlzGeftesHFTwvEsiu';
const _revenuecatApiKeyAndroid = 'goog_TWLbpyQfNSsCWUcBEXOHOqTgPuf';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Debug logging disabled for production builds
  if (kDebugMode) {
    await Purchases.setLogLevel(LogLevel.debug);
  } else {
    await Purchases.setLogLevel(LogLevel.error);
  }
  final rcConfig = PurchasesConfiguration(
    Platform.isAndroid ? _revenuecatApiKeyAndroid : _revenuecatApiKeyIOS,
  )
    ..appUserID = null
    ..entitlementVerificationMode = EntitlementVerificationMode.informational;
  await Purchases.configure(rcConfig);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DrawerProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RevenueCatProvider()..start()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}