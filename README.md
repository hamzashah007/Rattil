# Rattil - Quran Learning App

A Flutter application for online Quran classes with subscription management.

## 📱 Features

- 🔐 Firebase Authentication (Email/Password)
- 📚 Package enrollment system (Premium Intensive, etc.)
- 💳 Apple In-App Purchase integration (planned)
- 👤 User profile management
- 🗑️ Account deletion (Apple App Store compliant)
- 🌓 Dark/Light theme support

## 🗄️ Database Structure

See **[FIRESTORE_STRUCTURE.md](FIRESTORE_STRUCTURE.md)** for complete documentation.

**Collections:**
- `users` - User profiles
- `transactions` - Payment records (anonymized on deletion)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Firebase project configured
- iOS/Android development environment

### Installation
```bash
flutter pub get
flutter run
```

## 📝 Documentation

- **Database Schema**: See `FIRESTORE_STRUCTURE.md`
- **Helper Functions**: See `lib/utils/firestore_helpers.dart`
- **Account Deletion**: Implemented in `lib/providers/auth_provider.dart`

