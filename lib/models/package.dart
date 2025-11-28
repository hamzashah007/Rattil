class Package {
  final int id;
  final String name;
  final int price;
  final String colorGradientStart;
  final String colorGradientEnd;
  final bool isPopular;

  Package({
    required this.id,
    required this.name,
    required this.price,
    required this.colorGradientStart,
    required this.colorGradientEnd,
    this.isPopular = false,
  });
}

final List<Package> packages = [
  Package(
    id: 1,
    name: 'Basic Recitation Package', // Updated name
    price: 10, // Updated price
    colorGradientStart: '0xFF34D399', // Emerald-400
    colorGradientEnd: '0xFF14b8a6', // Teal-500
  ),
  Package(
    id: 2,
    name: 'Intermediate Package', // Already correct
    price: 18, // Updated price
    colorGradientStart: '0xFF14b8a6', // Teal-500
    colorGradientEnd: '0xFF06b6d4', // Cyan-600
    isPopular: true,
  ),
  Package(
    id: 3,
    name: 'Premium / Intensive Package', // Updated name
    price: 25, // Updated price
    colorGradientStart: '0xFF06b6d4', // Cyan-600
    colorGradientEnd: '0xFF2563eb', // Blue-600
  ),
];
