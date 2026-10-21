# Contributing to Campus Hub & NCV Companion

Thanks for helping students in South African colleges and TVET institutions. Every fix and suggestion matters.

## Ways to help

- **Report a bug** with the bug report template.
- **Suggest a feature** with the feature request template. Explain which learner problem it solves.
- **Fix an issue.** Look for labels such as `good first issue` or `help wanted`.
- **Check the content.** ICASS thresholds and NCV rules must match the current DHET guidelines. If you find a mismatch, open an issue and cite the source.

## Development setup

- Campus Hub (Android): see the Android section of the [README](README.md).
- NCV Companion (Flutter): see [`ncv_companion/README.md`](ncv_companion/README.md).

Never commit secrets. Keep `google-services.json`, `.env`, keystores, and API keys out of Git. Use the example files and environment variables instead.

## Branches and commits

1. Fork the repository, or create a branch from `main` for trusted contributors. Use a descriptive name such as `fix/icass-rounding` or `feat/pdf-bookmarks`.
2. Keep each pull request focused on one change.
3. Write clear commit messages in the imperative mood, such as `Fix ICASS rounding for 0.5 marks`.

## Quality checks before you open a pull request

For NCV Companion:

```bash
cd ncv_companion
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

For Campus Hub, run the Gradle unit tests from Android Studio or with `./gradlew testDebugUnitTest` once the wrapper is available.

Add or update tests for any rule change. The ICASS calculator in `ncv_companion/lib/features/icass/domain/` must stay pure and fully covered.

## Pull requests

- Fill in the pull request template.
- Link the issue that the change addresses.
- Include screenshots or a short screen recording for UI changes.
- Keep the diff small. Large refactors should start with an issue to discuss the approach.

## Code style

- Dart: follow `analysis_options.yaml`, which includes `flutter_lints`.
- Kotlin: follow the Android Studio default formatter.
- Keep TVET rules and pass percentages in one place (`app_constants.dart`), not scattered through widgets.

## Code of conduct

By participating, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).
