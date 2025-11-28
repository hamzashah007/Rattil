import 'package:flutter/material.dart';
import 'package:rattil/widgets/review_card.dart';
import 'package:rattil/utils/theme_colors.dart';

class StudentReviewsSection extends StatelessWidget {
  final bool isDarkMode;
  const StudentReviewsSection({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Reviews',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? ThemeColors.darkText : ThemeColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              ReviewCard(
                name: 'Ahmad Hassan',
                review: 'Excellent teaching methods. My Tajweed has improved significantly!',
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 12),
              ReviewCard(
                name: 'Fatima Ali',
                review: 'Very patient tutors. Highly recommend for beginners.',
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 80),
            ],
          ),
        ],
      ),
    );
  }
}
