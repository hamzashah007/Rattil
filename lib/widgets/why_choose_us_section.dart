import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/widgets/feature_card.dart';

class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    debugPrint('WhyChooseUsSection: isDarkMode=$isDarkMode');
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
              color: isDarkMode ? Colors.white : Colors.black,
              letterSpacing: -1,
              wordSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              FeatureCard(
                icon: '👨‍🏫',
                title: 'Qualified Tutors',
                description: 'Learn from certified Quran teachers',
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: '💬',
                title: 'Live Sessions',
                description: 'Interactive classes',
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: '📖',
                title: 'Start from Basic Level',
                description: 'Begin your Quran learning journey from the fundamentals',
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: '🤝',
                title: 'Personalized Guidance',
                description: 'Receive individual attention and support from tutors',
              ),
                SizedBox(height: 80),
            ],
          ),
        ],
      ),
    );
  }
}
