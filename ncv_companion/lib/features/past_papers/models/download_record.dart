enum DownloadStatus { queued, downloading, completed, failed }

/// Local state of one offline PDF. Persisted in Hive, and the bytes live on disk.
class DownloadRecord {
  const DownloadRecord({
    required this.paperId,
    required this.title,
    required this.sourcePath,
    required this.status,
    required this.updatedAt,
    this.progress = 0,
    this.localPath,
    this.error,
  });

  final String paperId;
  final String title;

  /// Storage object path, needed to (re)start the download.
  final String sourcePath;
  final DownloadStatus status;
  final DateTime updatedAt;

  /// 0.0 to 1.0
  final double progress;

  /// Absolute path of the finished PDF in the app documents directory.
  final String? localPath;
  final String? error;

  bool get isComplete => status == DownloadStatus.completed && localPath != null;
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  DownloadRecord copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
    bool clearError = false,
    DateTime? updatedAt,
  }) {
    return DownloadRecord(
      paperId: paperId,
      title: title,
      sourcePath: sourcePath,
      status: status ?? this.status,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      error: clearError ? null : (error ?? this.error),
    );
  }

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
        paperId: json['paper_id'] as String,
        title: json['title'] as String? ?? 'Past paper',
        sourcePath: json['source_path'] as String,
        status: DownloadStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DownloadStatus.failed,
        ),
        updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        localPath: json['local_path'] as String?,
        error: json['error'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'paper_id': paperId,
        'title': title,
        'source_path': sourcePath,
        'status': status.name,
        'updated_at': updatedAt.toIso8601String(),
        'progress': progress,
        'local_path': localPath,
        'error': error,
      };
}
