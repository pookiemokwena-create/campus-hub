/// Mirrors public.subjects.
class Subject {
  const Subject({
    required this.id,
    required this.code,
    required this.title,
    required this.nqfLevel,
    required this.isFundamental,
    required this.passPercentage,
    this.vocationalStream,
  });

  final String id;
  final String code;
  final String title;
  final int nqfLevel;

  /// Fundamental = languages, Maths / Maths Literacy, Life Orientation.
  /// These use ICASS 25% / exam 75%. Vocational subjects use 50/50.
  final bool isFundamental;

  /// Sub-minimum and final pass mark: 50 vocational, 40 LO/FAL, 30 Maths.
  final int passPercentage;

  /// Null for fundamental subjects, which are shared across streams.
  final String? vocationalStream;

  /// True if a learner on [nqfLevel] / [stream] should see this subject.
  bool appliesTo({required int nqfLevel, required String stream}) {
    if (this.nqfLevel != nqfLevel) return false;
    return isFundamental || vocationalStream == stream;
  }

  String get thresholdLabel => switch (passPercentage) {
        50 => 'Vocational 50%',
        40 => 'Language / LO 40%',
        30 => 'Maths 30%',
        _ => '$passPercentage%',
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        nqfLevel: (json['nqf_level'] as num?)?.toInt() ?? 2,
        isFundamental: json['is_fundamental'] as bool? ?? false,
        passPercentage: (json['pass_percentage'] as num?)?.toInt() ?? 50,
        vocationalStream: json['vocational_stream'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'nqf_level': nqfLevel,
        'is_fundamental': isFundamental,
        'pass_percentage': passPercentage,
        'vocational_stream': vocationalStream,
      };
}
