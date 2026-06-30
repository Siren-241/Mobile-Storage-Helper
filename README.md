# storage_query_engine

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Project Structure
(for reference only)
```
lib/
│
├── core/                     # Shared infrastructure
│   ├── database/
│   ├── workers/
│   ├── constants/
│   ├── utils/
│   └── services/             # Generic services (logging, permissions, etc.)
│
├── models/
│   └── media_file.dart
│
├── repositories/             # All Isar access
│   └── media_repository.dart
│
├── features/
│   ├── indexing/
│   │   ├── scanner.dart
│   │   ├── indexing_manager.dart
│   │   └── media_indexer.dart
│   │
│   ├── enrichment/
│   │   ├── image/
│   │   ├── video/
│   │   ├── pdf/
│   │   └── enrichment_manager.dart
│   │
│   ├── search/
│   │   ├── search_engine.dart
│   │   └── smart_search.dart
│   │
│   └── gallery/
│       ├── screens/
│       └── widgets/
│
└── main.dart
```