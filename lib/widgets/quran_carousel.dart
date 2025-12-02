import 'package:flutter/material.dart';

class QuranCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  const QuranCarousel({Key? key, required this.imageUrls, this.height = 180}) : super(key: key);

  @override
  State<QuranCarousel> createState() => _QuranCarouselState();
}

class _QuranCarouselState extends State<QuranCarousel> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      int nextPage = (_currentIndex + 1) % widget.imageUrls.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = nextPage);
      return true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetImages = [
      'assets/quran carousel/banner_1.png',
      'assets/quran carousel/banner_2.png',
      'assets/quran carousel/banner_3.png',
    ];

    if (assetImages.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text('No banners available', style: TextStyle(color: Colors.grey, fontSize: 18)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 16),
      child: AspectRatio(
        aspectRatio: 4 / 3, // <-- For 1600x1200 images (full display)
        child: PageView.builder(
          controller: _pageController,
          itemCount: assetImages.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return Image.asset(
              assetImages[index],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Image not found', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
