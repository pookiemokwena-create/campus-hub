import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';

/// Offline-first read strategy used by catalogue and profile repositories:
///
///  1. If connectivity says we are online, try the network and refresh the cache.
///  2. If the network is unavailable (by connectivity or by a failed request),
///     return the cached copy from Hive.
///  3. If there is no cache either, throw an [OfflineException] with a clear message.
///
/// Non-network errors (RLS denial, bad input) are rethrown and never hidden
/// behind stale data.
Future<T> remoteFirst<T>({
  required ConnectivityGate gate,
  required Future<T> Function() remote,
  required T? Function() local,
  required String offlineMessage,
}) async {
  if (await gate.isOnline) {
    try {
      return await remote();
    } catch (error) {
      if (!isNetworkError(error)) rethrow;
    }
  }

  final cached = local();
  if (cached != null) return cached;

  throw OfflineException(offlineMessage);
}
