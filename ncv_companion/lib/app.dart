import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/sync/sync_coordinator.dart';
import 'core/theme/app_theme.dart';

class NcvCompanionApp extends ConsumerWidget {
  const NcvCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the background sync coordinator alive for the whole app lifetime
    // (connectivity + auth listeners flush pending offline writes).
    ref.watch(syncCoordinatorProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'NCV Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
