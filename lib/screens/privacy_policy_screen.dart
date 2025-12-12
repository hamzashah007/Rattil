// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:rattil/utils/app_colors.dart';
// import 'package:rattil/utils/theme_colors.dart';
// import 'package:provider/provider.dart';
// import 'package:rattil/providers/theme_provider.dart';

// class PrivacyPolicyScreen extends StatefulWidget {
//   const PrivacyPolicyScreen({Key? key}) : super(key: key);

//   @override
//   State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
// }

// class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;

//   static const String privacyPolicyUrl =
//       'https://docs.google.com/document/d/1mzfze5c8wibnWrzIAR3bHWwKkA0o_tIzkKsXaoFxflM/edit?usp=sharing';

//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             setState(() {
//               _isLoading = true;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//             });
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(privacyPolicyUrl));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final isDark = themeProvider.isDarkMode;
//     final bgColor = isDark ? ThemeColors.darkBg : ThemeColors.lightBg;
//     final textColor = isDark ? ThemeColors.darkText : ThemeColors.lightText;

//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         title: Text(
//           'Privacy Policy',
//           style: TextStyle(color: textColor),
//         ),
//         backgroundColor: bgColor,
//         iconTheme: IconThemeData(color: AppColors.teal500),
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading)
//             Center(
//               child: CircularProgressIndicator(
//                 color: AppColors.teal500,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
