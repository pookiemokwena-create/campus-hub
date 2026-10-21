# Campus Hub & NCV Companion

This monorepo contains two student-focused apps for South African TVET and college learners:

| Project | Folder | Stack | What it does |
|---|---|---|---|
| **Campus Hub** | `app/` (root Gradle project) | Kotlin, Jetpack Compose, Material 3, Room, Firebase | Centralised campus communication: announcements feed, Q&A, messages, notifications, and event schedules, with email-verified sign-in. |
| **NCV Companion** | `ncv_companion/` | Flutter (Dart 3), Riverpod, go_router, Supabase, Hive CE | Offline-first study companion for NCV Level 2–4 learners: ICASS and exam calculator with DHET pass thresholds, a past-paper library with offline PDFs, and an AI tutor. |

Each project has its own setup guide. See [`ncv_companion/README.md`](ncv_companion/README.md) for the Flutter app and backend.

## Campus Hub (Android)

### Requirements

- Android Studio (current stable), JDK 11 or newer
- Android SDK with API 36 installed
- A Firebase project with Authentication (email link), Cloud Firestore, App Check, and Firebase AI enabled

### Setup

1. Add your Firebase configuration as `app/google-services.json`. This file is not committed. Without it the build still runs, but Firebase features are disabled (`missingGoogleServicesStrategy = WARN`).
2. Copy `.env.example` to `.env` and set `GEMINI_API_KEY` if you use the AI features. `.env` is git-ignored.
3. Open the repository root in Android Studio and sync Gradle.
4. Run the `app` configuration on a device or emulator (minimum API 24).

Release builds read the signing key from the environment variables `KEYSTORE_PATH`, `STORE_PASSWORD`, and `KEY_PASSWORD`. Never commit keystores.

## NCV Companion (Flutter)

```bash
cd ncv_companion
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Full instructions, the Supabase setup, and the architecture are in [`ncv_companion/README.md`](ncv_companion/README.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Please follow our [Code of Conduct](CODE_OF_CONDUCT.md). To report a security issue, see [SECURITY.md](SECURITY.md).

## License

No license has been chosen yet. Until one is added, all rights are reserved by the author.
