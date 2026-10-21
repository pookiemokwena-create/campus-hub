import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// True when at least one interface is up.
/// This reports interface state only, not internet reachability (captive
/// portals and dead routers still report "wifi"). Repositories therefore
/// also treat request failures as offline and fall back to Hive.
bool hasNetwork(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

/// Wi-Fi or Ethernet. Used to decide whether large PDF downloads may run.
bool hasUnmeteredNetwork(List<ConnectivityResult> results) => results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

/// Imperative checks for non-widget code (repositories, download queue).
class ConnectivityGate {
  const ConnectivityGate(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> get isOnline async =>
      hasNetwork(await _connectivity.checkConnectivity());

  Future<bool> get isUnmetered async =>
      hasUnmeteredNetwork(await _connectivity.checkConnectivity());
}

/// Live stream of interface changes (Wi-Fi <-> mobile data, airplane mode, ...).
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivityResults(Ref ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
}

/// Synchronous view for widgets. Assume online until the first reading arrives.
@Riverpod(keepAlive: true)
bool isOnline(Ref ref) {
  final results = ref.watch(connectivityResultsProvider).value;
  return results == null || hasNetwork(results);
}

@Riverpod(keepAlive: true)
ConnectivityGate connectivityGate(Ref ref) =>
    ConnectivityGate(Connectivity());
