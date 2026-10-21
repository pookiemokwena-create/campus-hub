import 'package:ncv_companion/core/models/subject.dart';

/// Mirrors public.past_papers. [filePath] is the object path inside the private
/// 'past-papers' storage bucket (stored in the file_url column).
class PastPaper {
  const PastPaper({
    required this.id,
    required this.subjectId,
    required this.year,
    required this.paperNumber,
    required this.filePath,
    required this.isMemo,
  });

  final String id;
  final String subjectId;
  final int year;
  final int paperNumber;
  final String filePath;
  final bool isMemo;

  String get kindLabel => isMemo ? 'Memo' : 'Question paper';

  String get label => '$kindLabel · Paper $paperNumber · $year';

  factory PastPaper.fromJson(Map<String, dynamic> json) => PastPaper(
        id: json['id'] as String,
        subjectId: json['subject_id'] as String,
        year: (json['year'] as num).toInt(),
        paperNumber: (json['paper_number'] as num?)?.toInt() ?? 1,
        filePath: json['file_url'] as String,
        isMemo: json['is_memo'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject_id': subjectId,
        'year': year,
        'paper_number': paperNumber,
        'file_url': filePath,
        'is_memo': isMemo,
      };
}

/// Full display title for lists and downloads, e.g. "MAT1 Mathematics · Memo · Paper 1 · 2025".
String paperTitleFor(PastPaper paper, Subject? subject) {
  final name = subject == null ? 'Subject' : '${subject.code} ${subject.title}';
  return '$name · ${paper.label}';
}
