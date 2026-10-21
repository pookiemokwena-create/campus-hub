import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a Stream (e.g. Supabase auth events) to GoRouter's refreshListenable,
/// so redirect guards re-run whenever the session changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
