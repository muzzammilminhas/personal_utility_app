class Recording {
  final String id;
  final String userId;
  final String title;
  final String notes;
  final String filePath;
  final int durationMs;

  final DateTime createdAt;

  const Recording({
    required this.id,
    required this.userId,
    required this.title,
    required this.notes,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      filePath: json['file_path'] as String,
      durationMs: json['duration_ms'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'notes': notes,
      'file_path': filePath,
      'duration_ms': durationMs,
    };
  }

  Recording copyWith({
    String? id,
    String? userId,
    String? title,
    String? notes,
    String? filePath,
    int? durationMs,
    DateTime? createdAt,
  }) {
    return Recording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedDuration {
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Recording('
        'id: $id, '
        'title: $title, '
        'duration: $formattedDuration, '
        'filePath: $filePath'
        ')';
  }
}
