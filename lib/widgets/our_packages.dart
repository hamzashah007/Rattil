import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/widgets/course_card.dart';
import 'package:rattil/utils/theme_colors.dart';

class FeaturedCoursesGrid extends StatelessWidget {
  final bool isDarkMode;
  final void Function(Package) onViewDetails;
  final void Function() onViewMore;

  const FeaturedCoursesGrid({
    Key? key,
    required this.isDarkMode,
    required this.onViewDetails,
    required this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final accentColor = ThemeColors.primaryTealDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Change section title
              Text(
                'Our Packages', // Updated from 'Featured Courses'
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              InkWell(
                onTap: onViewMore,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Lower the View More text
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5), // Move View More text a bit lower
                      child: Text(
                        'View More',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Made View More text a bit smaller
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right, color: ThemeColors.primaryTealDark, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8), // Add a little padding above the cards
          GridView.builder(
            padding: EdgeInsets.zero, // Remove any default grid padding
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.62, // Lower aspect ratio for taller cards
            ),
            itemCount: packages.take(2).length,
            itemBuilder: (context, index) {
              final pkg = packages[index];
              return CourseCard(
                package: pkg,
                isDarkMode: isDarkMode,
                onViewDetails: () => onViewDetails(pkg),
              );
            },
          ),
        ],
      ),
    );
  }
}
