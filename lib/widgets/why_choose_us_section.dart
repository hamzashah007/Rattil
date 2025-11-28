import 'package:flutter/material.dart';
import 'package:rattil/widgets/feature_card.dart';
import 'package:rattil/utils/theme_colors.dart';

class WhyChooseUsSection extends StatelessWidget {
  final bool isDarkMode;
  const WhyChooseUsSection({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Rattil?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? ThemeColors.darkText : ThemeColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              FeatureCard(
                icon: '👨‍🏫',
                title: 'Qualified Tutors',
                description: 'Learn from certified Quran teachers',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: '📚',
                title: 'Flexible Learning',
                description: 'Study at your own pace and schedule',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: '🏆',
                title: 'Certificates',
                description: 'Get certified upon course completion',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: '💬',
                title: 'Live Sessions',
                description: 'Interactive one-on-one classes',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
