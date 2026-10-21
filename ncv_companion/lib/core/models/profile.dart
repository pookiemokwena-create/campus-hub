import 'dart:math' as math;

import 'package:ncv_companion/core/config/app_constants.dart';

/// Mirrors public.profiles. `daily_ai_queries` is server-owned; the client only reads it.
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.collegeName,
    required this.nqfLevel,
    required this.vocationalStream,
    required this.dailyAiQueries,
    this.aiQuotaDate,
  });

  final String id;
  final String fullName;
  final String collegeName;
  final int nqfLevel;
  final String vocationalStream;
  final int dailyAiQueries;

  /// Date-only value (SAST calendar day) on which [dailyAiQueries] was counted.
  final DateTime? aiQuotaDate;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'Student' : parts.first;
  }

  /// Mirrors the server rule: the counter only counts when it belongs to today.
  int usedQueriesOn(DateTime sastDay) {
    final quotaDay = aiQuotaDate;
    if (quotaDay == null || !_sameDay(quotaDay, sastDay)) return 0;
    return dailyAiQueries;
  }

  /// Remaining AI queries for the current SAST day.
  int remainingAiQueries(DateTime nowUtc) {
    final sast = nowUtc.add(AppConstants.sastOffset);
    final today = DateTime.utc(sast.year, sast.month, sast.day);
    final used = usedQueriesOn(today);
    return math.max(0, AppConstants.aiDailyQueryLimit - used);
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final quota = json['ai_quota_date'] as String?;
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      collegeName: json['college_name'] as String? ?? '',
      nqfLevel: (json['nqf_level'] as num?)?.toInt() ?? 2,
      vocationalStream: json['vocational_stream'] as String? ?? '',
      dailyAiQueries: (json['daily_ai_queries'] as num?)?.toInt() ?? 0,
      aiQuotaDate: quota == null ? null : _parseDateOnly(quota),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'college_name': collegeName,
        'nqf_level': nqfLevel,
        'vocational_stream': vocationalStream,
        'daily_ai_queries': dailyAiQueries,
        'ai_quota_date': aiQuotaDate == null ? null : _formatDateOnly(aiQuotaDate!),
      };

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _parseDateOnly(String value) {
    final parts = value.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String _formatDateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
