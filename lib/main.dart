import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/auth_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';
import 'package:rattil/providers/revenuecat_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/screens/splashscreen.dart';

import 'firebase_options.dart';

const _revenuecatApiKey = 'appl_pMSdZUXXAVlzGeftesHFTwvEsiu';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Purchases.setLogLevel(LogLevel.debug); // Disable in production
  final rcConfig = PurchasesConfiguration(_revenuecatApiKey)
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
        ChangeNotifierProvider(create: (_) => RevenueCatProvider()..start()),
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