import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackLog {
  final String id;
  final String uid;
  final int rating;
  final String comment;
  final String favoriteFeature;
  final DateTime createdAt;

  FeedbackLog({
    required this.id,
    required this.uid,
    required this.rating,
    required this.comment,
    required this.favoriteFeature,
    required this.createdAt,
  });

  factory FeedbackLog.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackLog(
      id: id,
      uid: map['uid'] ?? '',
      rating: (map['rating'] ?? 5).toInt(),
      comment: map['comment'] ?? '',
      favoriteFeature: map['favoriteFeature'] ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'rating': rating,
      'comment': comment,
      'favoriteFeature': favoriteFeature,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  try {
    final dynamic dateTime = raw.toDate();
    if (dateTime is DateTime) return dateTime;
  } catch (_) {}
  return null;
}
