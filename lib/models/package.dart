class Package {
  final int id;
  final String name;
  final int price;
  final String duration;
  final String time;
  final double rating;
  final int reviews;
  final int students;
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
    required this.rating,
    required this.reviews,
    required this.students,
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
    rating: 4.9,
    reviews: 243,
    students: 1250,
    features: [
      'Tajweed Rules',
      'Basic Pronunciation',
      'Qualified Tutors',
      'Progress Tracking',
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
    rating: 4.9,
    reviews: 312,
    students: 980,
    features: [
      'Tajweed Rules',
      'Tafseer (Quranic Interpretation)',
      'Qualified Tutors',
      'Progress Tracking',
      'Study Materials',
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
    rating: 5.0,
    reviews: 189,
    students: 650,
    features: [
      'Tajweed Rules',
      'Tafseer (Interpretation)',
      'Hifz (Memorization)',
      'One-on-One Sessions',
      'Priority Support',
      'Certificates',
    ],
    colorGradientStart: 0xFF06b6d4,
    colorGradientEnd: 0xFF2563eb,
    level: 'advanced',
  ),
];
