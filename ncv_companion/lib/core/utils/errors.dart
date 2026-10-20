import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the feature needs the network and no cached data exists.
class OfflineException implements Exception {
  const OfflineException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// True for failures that mean "the server could not be reached".
/// These trigger the local-cache fallback. Other errors are real and must surface.
bool isNetworkError(Object error) {
  return error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException ||
      error is AuthRetryableFetchException;
}

/// Short, student-friendly message for a SnackBar or an error card.
String friendlyError(Object error) {
  if (error is OfflineException) return error.message;
  if (isNetworkError(error)) {
    return "Can't reach the server. Showing saved data where available.";
  }
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is StorageException) return error.message;
  return 'Something went wrong. Please try again.';
}
