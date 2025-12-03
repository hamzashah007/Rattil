import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/screens/trial_request_success_screen.dart';

class PackageCard extends StatefulWidget {
  final Package package;
  final int delay;
  final VoidCallback? onEnroll;
  const PackageCard({Key? key, required this.package, required this.delay, this.onEnroll}) : super(key: key);

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(_controller);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    debugPrint('PackageCard: ${widget.package.name}, isDarkMode=$isDarkMode');
    final pkg = widget.package;

    // Modern, softer gradients for each package type
    List<Color> gradient;
    switch (pkg.name) {
      case 'Premium Intensive':
        gradient = [Color(0xFFFFE0B2), Color(0xFFFFA726)]; // Soft Orange to Amber
        break;
      case 'Intermediate Package':
        gradient = [Color(0xFF3949AB), Color(0xFF90CAF9)]; // Indigo to Light Blue
        break;
      case 'Basic Recitation':
        gradient = [Color(0xFFA5D6A7), Color(0xFF388E3C)]; // Light Green to Deep Green
        break;
      default:
        gradient = [Color(pkg.colorGradientStart), Color(pkg.colorGradientEnd)]; // Fallback
    }

    final cardBg = isDarkMode ? Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Color(0xFF111827);
    final subtitleColor = isDarkMode ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
    final detailBoxBg = isDarkMode ? Color(0xFF374151) : Color(0xFFF9FAFB);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isHovered ? 0.12 : 0.08),
                    blurRadius: isHovered ? 24 : 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {}, // TODO: Navigate to detail
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header Section
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
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
                    // Card Content Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28), // Slightly increased bottom padding for comfortable spacing
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg.name,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        
                                        height: 1,
                                        letterSpacing: -1,
                                        wordSpacing: -2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('\$${pkg.price}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0d9488), height: 1)),
                                    Text('per month', style: TextStyle(fontSize: 14, color: subtitleColor)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Course Details Box
                          Container(
                            decoration: BoxDecoration(
                              color: detailBoxBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.schedule, color: Color(0xFF0d9488), size: 18),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Duration', style: TextStyle(fontSize: 12, color: subtitleColor)),
                                        Text(pkg.duration, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.menu_book, color: Color(0xFF0d9488), size: 18),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Session Time', style: TextStyle(fontSize: 12, color: subtitleColor)),
                                        Text(pkg.time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Features Section
                          Text("What's Included:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...pkg.features
                                .where((feature) => feature != 'Progress Tracking' && feature != 'Study Materials' && feature != 'One-on-One Sessions' && feature != 'Priority Support' && feature != 'Certificates')
                                .map((feature) {
                                  // Remove any parentheses and their contents
                                  final cleaned = feature.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
                                  return cleaned.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF0d9488),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(Icons.check, color: Color.fromARGB(255, 255, 255, 255), size: 14),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(cleaned, style: TextStyle(fontSize: 14, color: isDarkMode ? Color(0xFFd1d5db) : Color(0xFF374151))),
                                          ],
                                        ),
                                      )
                                    : SizedBox.shrink();
                                })
                                .toList(),
    
                                
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Enroll Button
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: widget.onEnroll,
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
                                    Text('Enroll Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
