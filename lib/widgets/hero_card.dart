import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';

class HeroCard extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onViewPackages;

  const HeroCard({
    Key? key,
    required this.isDarkMode,
    required this.onViewPackages,
  }) : super(key: key);

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final gradient = ThemeColors.heroGradient;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16), // Added left/right padding
      child: Stack(
        children: [
          Container(
            width: double.infinity, // Make card full width
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📖', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text(
                  'Nuzul ul Quran',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'For Adults and Kids',
                  style: TextStyle(
                    fontSize: 18,
                    color: ThemeColors.tealLight,
                  ),
                ),
                const SizedBox(height: 24),
                MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true),
                  onExit: (_) => setState(() => isHovered = false),
                  child: AnimatedScale(
                    scale: isHovered ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ThemeColors.primaryTealDark,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: ThemeColors.primaryTeal,
                      ),
                      onPressed: widget.onViewPackages,
                      child: const Text(
                        'View Packages',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Decorative circles
          Positioned(
            top: -32,
            right: -32,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
