import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/models/profile.dart';
import 'package:ncv_companion/core/router/app_routes.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/sync/sync_coordinator.dart';
import 'package:ncv_companion/core/theme/app_theme.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/core/utils/format.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';
import 'package:ncv_companion/features/icass/providers/icass_providers.dart';
import 'package:ncv_companion/features/past_papers/models/download_record.dart';
import 'package:ncv_companion/features/past_papers/providers/downloads_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final overview = ref.watch(icassOverviewProvider);
    final downloads = ref.watch(downloadsProvider).values.toList(growable: false);
    final wifiOnly = ref.watch(wifiOnlyDownloadsProvider);
    final sync = ref.watch(syncCoordinatorProvider);
    final online = ref.watch(isOnlineProvider);
    final remaining =
        profile?.remainingAiQueries(DateTime.now().toUtc()) ?? AppConstants.aiDailyQueryLimit;

    return Scaffold(
      appBar: AppBar(title: const Text('NCV Companion')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await ref.read(syncCoordinatorProvider.notifier).syncNow();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GreetingCard(
              profile: profile,
              loading: profileAsync.isLoading && profile == null,
              error: profileAsync.hasError && profile == null
                  ? friendlyError(profileAsync.error!)
                  : null,
            ),
            const SizedBox(height: 12),
            _IcassOverviewCard(
              overview: overview,
              onOpen: () => context.go(AppRoutes.icass),
            ),
            const SizedBox(height: 12),
            _DownloadQueueCard(
              downloads: downloads,
              wifiOnly: wifiOnly,
              online: online,
              onToggleWifiOnly: (value) =>
                  ref.read(wifiOnlyDownloadsProvider.notifier).setEnabled(value),
              onRetryQueue: () => ref.read(downloadsProvider.notifier).processQueue(),
              onOpen: () => context.go(AppRoutes.papers),
            ),
            const SizedBox(height: 12),
            _AiQuotaCard(
              remaining: remaining,
              limit: AppConstants.aiDailyQueryLimit,
              onOpen: () => context.go(AppRoutes.tutor),
            ),
            const SizedBox(height: 12),
            _SyncFootnote(state: sync, online: online),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.profile,
    required this.loading,
    required this.error,
  });

  final Profile? profile;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String headline;
    final String detail;
    if (error != null) {
      headline = 'Welcome back';
      detail = error!;
    } else if (loading) {
      headline = 'Loading your profile…';
      detail = '';
    } else {
      headline = 'Hi, ${profile?.firstName ?? 'there'}';
      detail = profile == null
          ? 'Your profile is not set up yet.'
          : '${profile!.collegeName.isEmpty ? 'NCV' : profile!.collegeName} · '
              'NQF ${profile!.nqfLevel} · ${profile!.vocationalStream}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.school, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: theme.textTheme.titleLarge),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IcassOverviewCard extends StatelessWidget {
  const _IcassOverviewCard({required this.overview, required this.onOpen});

  final IcassOverview overview;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('ICASS progress', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${formatPercent(overview.averageIcass)}% average ICASS',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overview.progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                overview.tracked == 0
                    ? 'Start with your first subject to see progress across all subjects.'
                    : '${overview.tracked} of ${overview.applicable} subjects tracked · '
                        '${overview.onTrack} on track · ${overview.needsAttention} need attention',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadQueueCard extends StatelessWidget {
  const _DownloadQueueCard({
    required this.downloads,
    required this.wifiOnly,
    required this.online,
    required this.onToggleWifiOnly,
    required this.onRetryQueue,
    required this.onOpen,
  });

  final List<DownloadRecord> downloads;
  final bool wifiOnly;
  final bool online;
  final ValueChanged<bool> onToggleWifiOnly;
  final VoidCallback onRetryQueue;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    int countWhere(bool Function(DownloadRecord) test) => downloads.where(test).length;
    final completed = countWhere((d) => d.status == DownloadStatus.completed);
    final queued = countWhere((d) => d.status == DownloadStatus.queued);
    final active = countWhere((d) => d.status == DownloadStatus.downloading);
    final failed = countWhere((d) => d.status == DownloadStatus.failed);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_for_offline_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Download queue', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(onPressed: onOpen, child: const Text('Library')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('$completed offline')),
                Chip(label: Text('$active downloading')),
                Chip(label: Text('$queued queued')),
                if (failed > 0)
                  ActionChip(
                    avatar: Icon(Icons.refresh, size: 18, color: AppTheme.danger),
                    label: Text('$failed failed · retry'),
                    onPressed: online ? onRetryQueue : null,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Download on Wi-Fi only'),
              subtitle: const Text('Saves mobile data. Turn off to use mobile data.'),
              value: wifiOnly,
              onChanged: onToggleWifiOnly,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiQuotaCard extends StatelessWidget {
  const _AiQuotaCard({
    required this.remaining,
    required this.limit,
    required this.onOpen,
  });

  final int remaining;
  final int limit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = limit - remaining;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('AI Tutor', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$remaining/$limit AI queries remaining today',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (used / limit).clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncFootnote extends StatelessWidget {
  const _SyncFootnote({required this.state, required this.online});

  final SyncState state;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final String text;
    if (state.syncing) {
      text = 'Syncing your changes…';
    } else if (state.lastError != null) {
      text = state.lastError!;
    } else if (!online) {
      text = 'Offline. Your changes are saved on this device.';
    } else if (state.lastSyncedAt != null) {
      final t = state.lastSyncedAt!.toLocal();
      text =
          'Last synced ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } else {
      text = 'Pull down to sync.';
    }

    return Text(text, style: muted, textAlign: TextAlign.center);
  }
}
