import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/utils/theme_colors.dart';

class CourseCard extends StatelessWidget {
  final Package package;
  final bool isDarkMode;
  final VoidCallback onViewDetails;

  const CourseCard({
    Key? key,
    required this.package,
    required this.isDarkMode,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> gradient;
    switch (package.name) {
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
        gradient = [Color(package.colorGradientStart), Color(package.colorGradientEnd)]; // Fallback
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 16, // Only a small red strip at the top
          // color: Colors.red.withOpacity(0.2), // Visual debugging: semi-transparent red background
        ),
        Container(
          width: double.infinity,
          height: 120, // Increased image height for larger card
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -16,
                left: -16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Center(
                child: Text('📖', style: TextStyle(fontSize: 48, color: Colors.white)),
              ),
            ],
          ),
        ),
        Text(
          package.name,
          style: TextStyle(
            fontSize: 16, // Bigger font for name
            fontWeight: FontWeight.w700,
            color: isDarkMode ? ThemeColors.darkText : ThemeColors.lightText,
          ),
        ),
        SizedBox(height: 3), // Reduced spacing
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              package.price == 10 ? '10\$' : package.price == 18 ? '18\$' : package.price.toString() + '\$', // Show 10$ or 18$
              style: TextStyle(
                fontSize: 14, // Set price font size to 14
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryTealDark,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '/mo', // Always show /mo
              style: TextStyle(fontSize: 12, color: Colors.grey), // Slightly bigger /mo
            ),
          ],
        ),
        Container(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
              backgroundColor: ThemeColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            onPressed: onViewDetails,
            child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), // Reduced font size
          ),
        ),
      ],
    );
  }
}
