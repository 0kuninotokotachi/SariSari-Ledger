# Project: SariSari-Ledger

## Overview
A lightweight, offline-first bookkeeping app for sari-sari store owners (ages 30-60) in the Philippines.
- Main Feature 1: Customer Credit Management (Utang tracking).
- Main Feature 2: Daily Sales Logging.
- Core Requirements: 100% Offline-first, ultra-lightweight, high performance on low-end smartphones, extremely simple UI.

## Tech Stack
- Framework: Flutter (Dart)
- Local Database: Isar DB
- Target Platforms: Android & iOS

## Common Commands
- Run app: `flutter run`
- Run tests: `flutter test`
- Analyze code: `flutter analyze`
- Code Generation (Isar): `dart run build_runner build --delete-conflicting-outputs`
- Clean build: `flutter clean && flutter pub get`

## Architecture & Directory Structure
Follow a simple layered architecture suited for a lightweight app:
```text
lib/
├── main.dart             # App entry point (calls DatabaseService.init())
├── models/               # Isar collection schemas (*.dart & generated *.g.dart)
│   ├── customer.dart
│   └── transaction.dart
├── services/             # Low-level DB access & Isar initialization
│   └── database_service.dart
├── providers/            # State management (connects UI to Services & handles business logic)
│   └── customer_provider.dart
├── screens/              # UI Screen pages (Home, CustomerList, Sales, etc.)
└── widgets/              # Reusable UI components (Buttons, Input fields, Cards)
```

## Coding & UI Guidelines
- **Offline First**: All data read/write operations must work without network calls.
- **UI/UX**: Keep forms simple, use large readable fonts and touch targets (optimized for 30-60 age group).
- **Currency**: Format money in Philippine Peso (`₱` or `PHP`).
- **Performance**: Keep widget trees clean, avoid unnecessary rebuilds, and minimize external packages.

## Agent Guidelines (for Claude Code)
- Write commit messages in **English**.
- When creating Isar models, remember to remind the user to run `build_runner`.