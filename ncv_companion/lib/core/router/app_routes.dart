/// Route paths. Use these constants everywhere; never hard-code strings.
abstract final class AppRoutes {
  static const auth = '/auth';
  static const home = '/home';
  static const icass = '/icass';
  static const papers = '/papers';
  static const tutor = '/tutor';

  /// Full-screen reader. Lives outside the bottom-nav shell.
  static const pdfReaderPattern = '/papers/read/:paperId';
  static String pdfReader(String paperId) => '/papers/read/$paperId';
}
