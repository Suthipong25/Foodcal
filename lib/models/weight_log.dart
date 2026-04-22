class WeightLog {
  final String date; // YYYY-MM-DD
  final double weightKg;
  final String? note;

  const WeightLog({
    required this.date,
    required this.weightKg,
    this.note,
  });

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      date: map['date'] as String? ?? '',
      weightKg: (map['weightKg'] as num? ?? 0).toDouble(),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'weightKg': weightKg,
      if (note != null) 'note': note,
    };
  }

  WeightLog copyWith({String? date, double? weightKg, String? note}) {
    return WeightLog(
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
    );
  }
}
