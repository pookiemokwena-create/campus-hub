import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ncv_companion/core/models/subject.dart';
import 'package:ncv_companion/core/providers/catalog_providers.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';
import 'package:ncv_companion/features/past_papers/data/paper_download_service.dart';
import 'package:ncv_companion/features/past_papers/data/past_papers_repository.dart';
import 'package:ncv_companion/features/past_papers/models/past_paper.dart';

part 'past_paper_providers.g.dart';

@Riverpod(keepAlive: true)
PastPapersRepository pastPapersRepository(Ref ref) {
  return PastPapersRepository(
    client: ref.watch(supabaseProvider),
    storage: ref.watch(localStorageProvider),
    gate: ref.watch(connectivityGateProvider),
  );
}

@Riverpod(keepAlive: true)
PaperDownloadService paperDownloadService(Ref ref) {
  return PaperDownloadService(ref.watch(supabaseProvider));
}

@riverpod
Future<List<PastPaper>> pastPaperCatalog(Ref ref) {
  ref.watch(authStateProvider);
  ref.watch(isOnlineProvider);
  return ref.watch(pastPapersRepositoryProvider).fetchCatalog();
}

@riverpod
PastPaper? paperById(Ref ref, String paperId) {
  final papers = ref.watch(pastPaperCatalogProvider).value ?? const <PastPaper>[];
  for (final paper in papers) {
    if (paper.id == paperId) return paper;
  }
  return null;
}

/// Nested filter state: NQF level > stream > subject > year.
/// Changing a parent filter clears its children.
class PaperFilterState {
  const PaperFilterState({
    required this.nqfLevel,
    this.stream,
    this.subjectId,
    this.year,
  });

  final int nqfLevel;
  final String? stream;
  final String? subjectId;
  final int? year;
}

/// Options for each dropdown and chip row, derived from the current filters.
class PaperFilterOptions {
  const PaperFilterOptions({
    required this.streams,
    required this.subjects,
    required this.years,
  });

  final List<String> streams;
  final List<Subject> subjects;
  final List<int> years;
}

@Riverpod(keepAlive: true)
class PaperFilters extends _$PaperFilters {
  bool _userChanged = false;

  @override
  PaperFilterState build() {
    // Use the learner's NQF level and stream as defaults until they change a filter.
    ref.listen(profileProvider, (previous, next) {
      final profile = next.value;
      if (profile != null && !_userChanged) {
        state = _defaultsFor(profile.nqfLevel, profile.vocationalStream);
      }
    });

    final profile = ref.read(profileProvider).value;
    return profile == null
        ? const PaperFilterState(nqfLevel: 2)
        : _defaultsFor(profile.nqfLevel, profile.vocationalStream);
  }

  PaperFilterState _defaultsFor(int nqfLevel, String stream) {
    return PaperFilterState(
      nqfLevel: nqfLevel,
      stream: stream.isEmpty ? null : stream,
    );
  }

  void setNqfLevel(int level) {
    _userChanged = true;
    state = PaperFilterState(nqfLevel: level);
  }

  void setStream(String? stream) {
    _userChanged = true;
    state = PaperFilterState(nqfLevel: state.nqfLevel, stream: stream);
  }

  void setSubject(String? subjectId) {
    _userChanged = true;
    state = PaperFilterState(
      nqfLevel: state.nqfLevel,
      stream: state.stream,
      subjectId: subjectId,
    );
  }

  void setYear(int? year) {
    _userChanged = true;
    state = PaperFilterState(
      nqfLevel: state.nqfLevel,
      stream: state.stream,
      subjectId: state.subjectId,
      year: year,
    );
  }
}

@riverpod
PaperFilterOptions paperFilterOptions(Ref ref) {
  final filters = ref.watch(paperFiltersProvider);
  final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
  final papers = ref.watch(pastPaperCatalogProvider).value ?? const <PastPaper>[];

  final levelSubjects = subjects.where((s) => s.nqfLevel == filters.nqfLevel).toList();

  final streams = levelSubjects
      .map((s) => s.vocationalStream)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();

  // Fundamental subjects always show. Vocational subjects show once a stream is chosen.
  final streamSubjects = levelSubjects
      .where((s) => s.isFundamental || (filters.stream != null && s.vocationalStream == filters.stream))
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  final subjectIds = streamSubjects.map((s) => s.id).toSet();
  final years = papers
      .where((p) => subjectIds.contains(p.subjectId))
      .map((p) => p.year)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  return PaperFilterOptions(streams: streams, subjects: streamSubjects, years: years);
}

@riverpod
List<PastPaper> filteredPapers(Ref ref) {
  final filters = ref.watch(paperFiltersProvider);
  final papers = ref.watch(pastPaperCatalogProvider).value ?? const <PastPaper>[];
  final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
  final subjectById = {for (final s in subjects) s.id: s};

  final result = papers.where((paper) {
    final subject = subjectById[paper.subjectId];
    if (subject == null) return false;
    if (subject.nqfLevel != filters.nqfLevel) return false;
    if (filters.stream != null &&
        !(subject.isFundamental || subject.vocationalStream == filters.stream)) {
      return false;
    }
    if (filters.subjectId != null && paper.subjectId != filters.subjectId) {
      return false;
    }
    if (filters.year != null && paper.year != filters.year) return false;
    return true;
  }).toList();

  result.sort((a, b) {
    final byYear = b.year.compareTo(a.year);
    if (byYear != 0) return byYear;
    final byPaper = a.paperNumber.compareTo(b.paperNumber);
    if (byPaper != 0) return byPaper;
    return (a.isMemo ? 1 : 0).compareTo(b.isMemo ? 1 : 0);
  });
  return result;
}
