import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/providers/catalog_providers.dart';
import 'package:ncv_companion/core/router/app_routes.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/core/widgets/status_views.dart';
import 'package:ncv_companion/features/past_papers/models/download_record.dart';
import 'package:ncv_companion/features/past_papers/models/past_paper.dart';
import 'package:ncv_companion/features/past_papers/presentation/widgets/paper_filter_bar.dart';
import 'package:ncv_companion/features/past_papers/presentation/widgets/paper_tile.dart';
import 'package:ncv_companion/features/past_papers/providers/downloads_providers.dart';
import 'package:ncv_companion/features/past_papers/providers/past_paper_providers.dart';

/// Past papers and memos, filtered NQF > stream > subject > year.
/// Each row shows its offline state. Tapping opens the reader, and if the
/// paper is not on the device yet, it starts a download first.
class PastPaperLibraryScreen extends ConsumerWidget {
  const PastPaperLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(pastPaperCatalogProvider);
    final papers = ref.watch(filteredPapersProvider);
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final subjectById = {for (final s in subjects) s.id: s};
    final downloads = ref.watch(downloadsProvider);
    final wifiOnly = ref.watch(wifiOnlyDownloadsProvider);
    final online = ref.watch(isOnlineProvider);

    Widget list;
    if (catalog.isLoading && papers.isEmpty) {
      list = const Center(child: CircularProgressIndicator());
    } else if (catalog.hasError && papers.isEmpty) {
      list = ErrorState(
        message: friendlyError(catalog.error!),
        onRetry: () => ref.invalidate(pastPaperCatalogProvider),
      );
    } else if (papers.isEmpty) {
      list = const EmptyState(
        icon: Icons.library_books_outlined,
        title: 'No papers match',
        message: 'Try another stream or subject, or clear the year filter.',
      );
    } else {
      list = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: papers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final paper = papers[index];
          final subject = subjectById[paper.subjectId];
          final title = paperTitleFor(paper, subject);
          return PaperTile(
            paper: paper,
            subjectTitle: title,
            download: downloads[paper.id],
            wifiOnly: wifiOnly,
            onOpen: () => _open(context, ref, paper, title, online),
            onDownload: () => _download(ref, paper, title, online, context),
            onRemove: () => ref.read(downloadsProvider.notifier).remove(paper.id),
            onRetry: () => ref.read(downloadsProvider.notifier).retry(paper.id),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Papers & Memos'),
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pastPaperCatalogProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const PaperFilterBar(),
          const Divider(height: 1),
          Expanded(child: list),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    PastPaper paper,
    String title,
    bool online,
  ) async {
    final record = ref.read(downloadsProvider)[paper.id];
    if (record != null && record.isComplete) {
      if (context.mounted) context.push(AppRoutes.pdfReader(paper.id));
      return;
    }
    if (!online) {
      _snack(context, 'Download this paper while you are online to read it offline.');
      return;
    }
    await ref.read(downloadsProvider.notifier).enqueue(paper, title: title);
    if (context.mounted) context.push(AppRoutes.pdfReader(paper.id));
  }

  Future<void> _download(
    WidgetRef ref,
    PastPaper paper,
    String title,
    bool online,
    BuildContext context,
  ) async {
    if (!online) {
      _snack(context, 'You are offline. The download will start when you reconnect.');
    }
    await ref.read(downloadsProvider.notifier).enqueue(paper, title: title);
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
