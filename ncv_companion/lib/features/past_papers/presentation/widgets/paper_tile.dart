import 'package:flutter/material.dart';

import 'package:ncv_companion/core/theme/app_theme.dart';
import 'package:ncv_companion/features/past_papers/models/download_record.dart';
import 'package:ncv_companion/features/past_papers/models/past_paper.dart';

/// One paper in the library, with its offline state on the trailing edge.
class PaperTile extends StatelessWidget {
  const PaperTile({
    super.key,
    required this.paper,
    required this.subjectTitle,
    required this.download,
    required this.wifiOnly,
    required this.onOpen,
    required this.onDownload,
    required this.onRemove,
    required this.onRetry,
  });

  final PastPaper paper;
  final String subjectTitle;
  final DownloadRecord? download;
  final bool wifiOnly;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            paper.isMemo ? Icons.fact_check_outlined : Icons.description_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(subjectTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _statusText(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: _DownloadIndicator(
          download: download,
          onDownload: onDownload,
          onRemove: onRemove,
          onRetry: onRetry,
        ),
      ),
    );
  }

  String _statusText() {
    final record = download;
    if (record == null) return paper.label;
    return switch (record.status) {
      DownloadStatus.completed => '${paper.label} · Available offline',
      DownloadStatus.downloading =>
        '${paper.label} · Downloading ${(record.progress * 100).round()}%',
      DownloadStatus.queued => wifiOnly
          ? '${paper.label} · Queued for Wi-Fi'
          : '${paper.label} · Queued',
      DownloadStatus.failed => '${paper.label} · Download failed',
    };
  }
}

class _DownloadIndicator extends StatelessWidget {
  const _DownloadIndicator({
    required this.download,
    required this.onDownload,
    required this.onRemove,
    required this.onRetry,
  });

  final DownloadRecord? download;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final record = download;

    if (record == null) {
      return IconButton(
        tooltip: 'Download for offline',
        icon: const Icon(Icons.download_for_offline_outlined),
        onPressed: onDownload,
      );
    }

    return switch (record.status) {
      DownloadStatus.completed => IconButton(
          tooltip: 'Available offline. Tap to remove.',
          icon: const Icon(Icons.offline_pin, color: AppTheme.success),
          onPressed: onRemove,
        ),
      DownloadStatus.downloading => SizedBox(
          width: 40,
          height: 40,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: record.progress > 0 ? record.progress : null,
            ),
          ),
        ),
      DownloadStatus.queued => const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.schedule),
        ),
      DownloadStatus.failed => IconButton(
          tooltip: 'Failed. Tap to retry.',
          icon: const Icon(Icons.error_outline, color: AppTheme.danger),
          onPressed: onRetry,
        ),
    };
  }
}
