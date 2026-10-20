import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/services/local_storage.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';

/// Boot sequence:
///  1. Open Hive boxes (must exist before anything reads cached data).
///  2. Initialise Supabase (restores the persisted session, works offline).
///  3. Inject the opened storage into Riverpod, then run the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  final storage = await LocalStorage.open();
  await initializeSupabase();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
      child: const NcvCompanionApp(),
    ),
  );
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Missing configuration.\n\n'
              'Run the app with:\n'
              'flutter run --dart-define-from-file=config/env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
