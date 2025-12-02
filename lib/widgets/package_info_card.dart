import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/utils/constants.dart';

class PackageInfoCard extends StatelessWidget {
  final Package package;
  final bool isDarkMode;
  const PackageInfoCard({Key? key, required this.package, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> gradient;
    switch (package.name) {
      case 'Premium Intensive':
        gradient = [Color(0xFFFFE0B2), Color(0xFFFFA726)];
        break;
      case 'Intermediate':
        gradient = [Color(0xFF3949AB), Color(0xFF90CAF9)];
        break;
      case 'Basic Recitation':
        gradient = [Color(0xFFA5D6A7), Color(0xFF388E3C)];
        break;
      default:
        gradient = [Color(package.colorGradientStart), Color(package.colorGradientEnd)];
    }
    final textColor = isDarkMode ? AppConstants.textColorDark : AppConstants.textColor;
    final subtitleColor = isDarkMode ? AppConstants.subtitleColorDark : AppConstants.subtitleColor;
    final detailBoxBg = isDarkMode ? AppConstants.detailBoxBgDark : AppConstants.detailBoxBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top card with gradient, bubbles, and book emoji
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
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
                child: Text('📖', style: TextStyle(fontSize: 64)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(package.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        Text('\$${package.price} / month', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
        const SizedBox(height: 16),
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
                  Icon(Icons.schedule, color: Color(0xFF009688), size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration', style: TextStyle(fontSize: 12, color: subtitleColor)),
                      Text(package.duration, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.menu_book, color: Color(0xFF009688), size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session Time', style: TextStyle(fontSize: 12, color: subtitleColor)),
                      Text(package.time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text("What's Included:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        ...package.features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFF009688),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(f, style: TextStyle(fontSize: 14, color: isDarkMode ? AppConstants.subtitleColorDark : Color(0xFF374151))),
            ],
          ),
        )),
      ],
    );
  }
}