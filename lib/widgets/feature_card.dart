import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';

class FeatureCard extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final bool isDarkMode;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = widget.isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtitleColor = widget.isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.14 : 0.08),
              blurRadius: isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(widget.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
