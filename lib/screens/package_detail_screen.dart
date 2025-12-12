import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/screens/trial_request_success_screen.dart';
import 'package:rattil/providers/iap_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PackageDetailScreen extends StatefulWidget {
  final Package package;
  const PackageDetailScreen({Key? key, required this.package}) : super(key: key);

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    // Remove IAP fetch logic from here, now handled globally in SplashScreen
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final appBarColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final detailBoxBg = isDarkMode ? const Color(0xFF374151) : const Color(0xFFF9FAFB);
    List<Color> gradient;
    switch (widget.package.name) {
      case 'Premium Intensive':
        gradient = [Color(0xFFFFE0B2), Color(0xFFFFA726)]; // Soft Orange to Amber
        break;
      case 'Intermediate':
        gradient = [Color(0xFF3949AB), Color(0xFF90CAF9)]; // Indigo to Light Blue
        break;
      case 'Basic Recitation':
        gradient = [Color(0xFFA5D6A7), Color(0xFF388E3C)]; // Light Green to Deep Green
        break;
      default:
        gradient = [Color(widget.package.colorGradientStart), Color(widget.package.colorGradientEnd)]; // Fallback
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Package Details', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        color: bgColor,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -64,
                    right: -64,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -48,
                    left: -48,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: SvgPicture.asset(
                      'assets/icon/app_icon.svg',
                      width: 80,
                      height: 80,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.package.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('\$${widget.package.price} / month', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF009688), fontFamily: 'Roboto', fontStyle: FontStyle.normal)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: detailBoxBg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF009688), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Duration', style: TextStyle(fontSize: 12, color: subtitleColor)),
                          Text(widget.package.duration, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: Color(0xFF009688), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Session Time', style: TextStyle(fontSize: 12, color: subtitleColor)),
                          Text(widget.package.time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("What's Included:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            ...widget.package.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFF009688),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.check, color: Color.fromARGB(255, 255, 255, 255), size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(feature, style: TextStyle(fontSize: 14, color: isDarkMode ? Color(0xFFd1d5db) : Color(0xFF374151))),
                ],
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Consumer<IAPProvider>(
                builder: (context, iapProvider, _) {
                  final isLoading = iapProvider.products.isEmpty;
                  ProductDetails? product;
                  try {
                    product = iapProvider.products.firstWhere(
                      (p) => p.id == widget.package.id.toString().padLeft(2, '0'),
                    );
                  } catch (e) {
                    product = null;
                  }
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isPurchasing || isLoading
                        ? null
                        : () async {
                            if (product != null) {
                              setState(() => _isPurchasing = true);
                              await Future.delayed(Duration(milliseconds: 2500));
                              iapProvider.buy(product);
                              setState(() => _isPurchasing = false);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Subscription product not found.')),
                              );
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF14b8a6), Color(0xFF0d9488)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isPurchasing || isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text('Subscribe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrialRequestSuccessScreen(
                        package: widget.package,
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF14b8a6)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Request Trial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
