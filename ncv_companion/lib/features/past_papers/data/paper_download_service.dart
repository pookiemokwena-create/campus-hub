import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/config/app_constants.dart';

class DownloadException implements Exception {
  const DownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Streams a PDF from Supabase Storage to the app documents directory.
///
/// Bytes go to `<id>.part` first and are renamed only when complete, so an
/// interrupted download never looks like a valid PDF.
class PaperDownloadService {
  PaperDownloadService(this._client);

  final SupabaseClient _client;

  Future<Directory> _papersDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/past_papers');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Downloads [storagePath] and returns the absolute local path.
  Future<String> download({
    required String paperId,
    required String storagePath,
    required void Function(double progress) onProgress,
  }) async {
    final signedUrl = await _client.storage
        .from(AppConstants.pastPapersBucket)
        .createSignedUrl(storagePath, AppConstants.signedUrlTtlSeconds);

    final dir = await _papersDirectory();
    final partFile = File('${dir.path}/$paperId.part');
    final targetFile = File('${dir.path}/$paperId.pdf');

    final httpClient = http.Client();
    IOSink? sink;
    try {
      final response =
          await httpClient.send(http.Request('GET', Uri.parse(signedUrl)));
      if (response.statusCode != 200) {
        throw DownloadException(
          'The server returned ${response.statusCode}. Try again later.',
        );
      }

      final total = response.contentLength ?? 0;
      sink = partFile.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.close();
      sink = null;

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetFile.path);
      onProgress(1);
      return targetFile.path;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {
        // The sink may already be closed. Ignore.
      }
      if (await partFile.exists()) {
        await partFile.delete();
      }
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  Future<void> deleteLocal(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
