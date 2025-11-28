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
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // No top/side margin
      // Removed minHeight constraint to prevent overflow
      child: Column(
        mainAxisSize: MainAxisSize.min, // Shrink to fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start, // Move all content to top
        children: [
          Container(
            width: double.infinity,
            height: 120, // Increased image height for larger card
            decoration: BoxDecoration(
              gradient: ThemeColors.heroGradient, // Use app's gradient green
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('📖', style: TextStyle(fontSize: 48, color: Colors.white)), // Larger font size
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
          SizedBox(height: 4), // Reduced spacing
          SizedBox(
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
      ),
    );
  }
}
