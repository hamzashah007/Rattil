import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';

class ReviewCard extends StatelessWidget {
  final String name;
  final String review;
  final bool isDarkMode;

  const ReviewCard({
    Key? key,
    required this.name,
    required this.review,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtitleColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    final avatarGradient = LinearGradient(
      colors: [ThemeColors.primaryTeal, ThemeColors.primaryTealDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: avatarGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) => const Icon(Icons.star, color: ThemeColors.yellowStar, size: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
