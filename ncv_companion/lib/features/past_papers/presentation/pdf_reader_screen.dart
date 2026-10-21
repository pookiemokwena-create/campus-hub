import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ncv_companion/core/providers/catalog_providers.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/widgets/status_views.dart';
import 'package:ncv_companion/features/past_papers/models/download_record.dart';
import 'package:ncv_companion/features/past_papers/models/past_paper.dart';
import 'package:ncv_companion/features/past_papers/providers/downloads_providers.dart';
import 'package:ncv_companion/features/past_papers/providers/past_paper_providers.dart';

/// Offline PDF reader with pinch zoom, +/- zoom buttons, previous/next page
/// and a "go to page" dialog. If the paper is not on the device yet, the
/// screen shows download progress and starts the download when possible.
class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.paperId});

  final String paperId;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  static const _minZoom = 1.0;
  static const _maxZoom = 4.0;
  static const _zoomStep = 0.5;

  PDFViewController? _controller;
  int _currentPage = 0; // zero-based
  int _pageCount = 0;
  double _zoom = _minZoom;
  String? _renderError;

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(downloadsProvider.select((m) => m[widget.paperId]));
    final paper = ref.watch(paperByIdProvider(widget.paperId));
    final subject = paper == null
        ? null
        : ref.watch(subjectByIdProvider(paper.subjectId));
    final online = ref.watch(isOnlineProvider);

    final title = paper == null
        ? (record?.title ?? 'Past paper')
        : paperTitleFor(paper, subject);
    final localPath = _readyPath(record);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      body: _buildBody(
        record: record,
        paper: paper,
        title: title,
        online: online,
        localPath: localPath,
      ),
      bottomNavigationBar: localPath == null || _renderError != null
          ? null
          : _ReaderToolbar(
              currentPage: _currentPage,
              pageCount: _pageCount,
              zoom: _zoom,
              onPrevious:
                  _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
              onNext: _currentPage < _pageCount - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
              onJump: _jumpToPage,
              onZoomOut:
                  _zoom > _minZoom ? () => _setZoom(_zoom - _zoomStep) : null,
              onZoomIn:
                  _zoom < _maxZoom ? () => _setZoom(_zoom + _zoomStep) : null,
            ),
    );
  }

  Widget _buildBody({
    required DownloadRecord? record,
    required PastPaper? paper,
    required String title,
    required bool online,
    required String? localPath,
  }) {
    if (localPath == null) {
      return _DownloadGate(
        record: record,
        canDownload: online && paper != null,
        online: online,
        onDownload: () => _startDownload(paper, title),
        onRetry: () =>
            ref.read(downloadsProvider.notifier).retry(widget.paperId),
      );
    }

    if (_renderError != null) {
      return ErrorState(
        message: 'This file could not be opened: $_renderError',
      );
    }

    return PDFView(
      filePath: localPath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageSnap: true,
      pageFling: true,
      fitPolicy: FitPolicy.WIDTH,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      onViewCreated: (controller) {
        _controller = controller;
        controller.getScale().then((scale) {
          if (mounted) setState(() => _zoom = scale);
        });
      },
      onRender: (pages) {
        if (!mounted) return;
        setState(() => _pageCount = pages ?? _pageCount);
      },
      onPageChanged: (page, total) {
        if (!mounted) return;
        setState(() {
          _currentPage = page ?? _currentPage;
          _pageCount = total ?? _pageCount;
        });
      },
      onError: (error) {
        if (mounted) setState(() => _renderError = '$error');
      },
      onPageError: (page, error) {
        if (mounted) setState(() => _renderError = '$error');
      },
    );
  }

  /// Returns the path only when the download is complete and the file still exists.
  String? _readyPath(DownloadRecord? record) {
    if (record == null || !record.isComplete) return null;
    final path = record.localPath!;
    // A single stat call on a local file is cheap enough to run in build().
    return File(path).existsSync() ? path : null;
  }

  Future<void> _startDownload(PastPaper? paper, String title) async {
    if (paper == null) return;
    await ref.read(downloadsProvider.notifier).enqueue(paper, title: title);
  }

  Future<void> _setZoom(double value) async {
    final controller = _controller;
    if (controller == null) return;
    final next = math.min(_maxZoom, math.max(_minZoom, value));
    await controller.setScale(next);
    if (mounted) setState(() => _zoom = next);
  }

  Future<void> _goToPage(int page) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setPage(page);
    if (mounted) setState(() => _currentPage = page);
  }

  Future<void> _jumpToPage() async {
    if (_controller == null || _pageCount == 0) return;

    final input = TextEditingController(text: '${_currentPage + 1}');
    final target = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Go to page (1 to $_pageCount)'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Page number'),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(int.tryParse(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(input.text)),
            child: const Text('Go'),
          ),
        ],
      ),
    );
    input.dispose();

    if (target == null) return;
    final page = math.min(_pageCount, math.max(1, target)) - 1;
    await _goToPage(page);
  }
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.currentPage,
    required this.pageCount,
    required this.zoom,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final int currentPage;
  final int pageCount;
  final double zoom;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onJump;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            TextButton.icon(
              onPressed: pageCount == 0 ? null : onJump,
              icon: const Icon(Icons.format_list_numbered, size: 18),
              label: Text(
                pageCount == 0
                    ? 'Loading…'
                    : 'Page ${currentPage + 1} of $pageCount',
              ),
            ),
            IconButton(
              tooltip: 'Zoom out',
              icon: const Icon(Icons.zoom_out),
              onPressed: onZoomOut,
            ),
            Text('${(zoom * 100).round()}%'),
            IconButton(
              tooltip: 'Zoom in',
              icon: const Icon(Icons.zoom_in),
              onPressed: onZoomIn,
            ),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the PDF when no complete local copy exists.
class _DownloadGate extends StatelessWidget {
  const _DownloadGate({
    required this.record,
    required this.canDownload,
    required this.online,
    required this.onDownload,
    required this.onRetry,
  });

  final DownloadRecord? record;
  final bool canDownload;
  final bool online;
  final VoidCallback onDownload;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = record;

    final Widget content = switch (current?.status) {
      DownloadStatus.downloading => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.downloading, size: 48),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: current!.progress > 0 ? current.progress : null,
            ),
            const SizedBox(height: 8),
            Text('Downloading ${(current.progress * 100).round()}%'),
          ],
        ),
      DownloadStatus.queued => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 48),
            const SizedBox(height: 16),
            Text('Queued', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'This paper downloads when you are online. "Wi-Fi only" is on by '
              'default to save mobile data.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      DownloadStatus.failed => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              current!.error ?? 'Download failed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry download'),
            ),
          ],
        ),
      // No record, or a record whose file has gone missing from disk.
      _ => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_for_offline_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'This paper is not on your device yet.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              online
                  ? 'Download it once and read it anywhere, with no data needed.'
                  : 'Connect to the internet to download this paper.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canDownload ? onDownload : null,
              icon: const Icon(Icons.download),
              label: const Text('Download for offline'),
            ),
          ],
        ),
    };

    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: content),
    );
  }
}
