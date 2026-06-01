class ScanHistory {
  final String id;
  final String userId;
  final String scannedText;

  final DateTime scannedAt;

  const ScanHistory({
    required this.id,
    required this.userId,
    required this.scannedText,
    required this.scannedAt,
  });

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scannedText: json['scanned_text'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanned_text': scannedText,
    };
  }

  @override
  String toString() {
    return 'ScanHistory('
        'id: $id, '
        'scannedText: $scannedText, '
        'scannedAt: $scannedAt'
        ')';
  }
}
