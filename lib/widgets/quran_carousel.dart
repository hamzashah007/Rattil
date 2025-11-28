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
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        },
      ),
    );
  }
}
