class Package {
  final int id;
  final String name;
  final int price;
  final String duration;
  final String time;
  final List<String> features;
  final int colorGradientStart;
  final int colorGradientEnd;
  final bool isPopular;
  final String level;

  Package({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.time,
    required this.features,
    required this.colorGradientStart,
    required this.colorGradientEnd,
    this.isPopular = false,
    required this.level,
  });
}

final List<Package> packages = [
  Package(
    id: 1,
    name: 'Basic Recitation',
    price: 10,
    duration: '3 classes per week',
    time: '20-25 minutes',
   
    features: [
      'Tajweed Rules',
      'Basic Pronunciation',
      'Qualified Tutors',
    ],
    colorGradientStart: 0xFF34D399,
    colorGradientEnd: 0xFF14b8a6,
    level: 'beginner',
  ),
  Package(
    id: 2,
    name: 'Intermediate',
    price: 18,
    duration: '3 classes per week',
    time: '40-45 minutes',

    features: [
      'Tajweed Rules',
      'Tafseer',
      'Qualified Tutors',
    
    ],
    colorGradientStart: 0xFF14b8a6,
    colorGradientEnd: 0xFF06b6d4,
    level: 'intermediate',
  ),
  Package(
    id: 3,
    name: 'Premium Intensive',
    price: 25,
    duration: '3 classes per week',
    time: '45-60 minutes',

    features: [
      'Tajweed Rules',
      'Tafseer',
      'Hifz',
      'Qualified Tutors',
    ],
    colorGradientStart: 0xFF06b6d4,
    colorGradientEnd: 0xFF2563eb,
    level: 'advanced',
  ),
];
