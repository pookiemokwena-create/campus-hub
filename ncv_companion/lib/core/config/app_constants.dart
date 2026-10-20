/// Central business rules. Keep TVET-specific numbers here, not scattered in widgets.
abstract final class AppConstants {
  // ---- AI Tutor -----------------------------------------------------------
  /// Mirrors the server-side limit in the consume_ai_query() SQL function.
  static const aiDailyQueryLimit = 20;

  /// How many prior chat turns are sent with each request (cost + latency control).
  static const aiHistoryTurns = 12;

  /// South Africa Standard Time is UTC+2 with no daylight saving.
  /// Quotas reset at local midnight in SAST, not UTC.
  static const sastOffset = Duration(hours: 2);

  // ---- Storage ------------------------------------------------------------
  static const pastPapersBucket = 'past-papers';
  static const signedUrlTtlSeconds = 60 * 60;

  // ---- ICASS / assessment rules (DHET NC(V) ICASS guidelines) -------------
  static const defaultTaskMaxScore = 100.0;

  /// ICASS share of the final mark. External exam is the remainder.
  static const icassWeightFundamental = 0.25;
  static const icassWeightVocational = 0.50;

  /// Reference sub-minimums. The live value comes from subjects.pass_percentage.
  static const passPercentageVocational = 50;
  static const passPercentageLanguageLo = 40;
  static const passPercentageMaths = 30;

  // ---- Catalogue ----------------------------------------------------------
  static const nqfLevels = <int>[2, 3, 4];

  // ---- Sync ---------------------------------------------------------------
  static const syncDebounce = Duration(seconds: 3);
}
