// Data Model: CheckInRecord
// Stores all check-in data captured BEFORE class starts.
// Fields defined per PRD Section 5 — Data Fields.

class CheckInRecord {
  final int? id; // Auto-increment primary key (SQLite)
  final String studentId; // Unique student identifier
  final DateTime checkinTime; // Timestamp when check-in was pressed
  final double checkinGpsLat; // Latitude captured at check-in
  final double checkinGpsLng; // Longitude captured at check-in
  final String qrCodeCheckin; // QR code value scanned at check-in
  final String prevTopic; // Topic covered in previous class
  final String expectedTopic; // Topic student expects to learn today
  final int moodBefore; // Mood score before class (1–5)

  const CheckInRecord({
    this.id,
    required this.studentId,
    required this.checkinTime,
    required this.checkinGpsLat,
    required this.checkinGpsLng,
    required this.qrCodeCheckin,
    required this.prevTopic,
    required this.expectedTopic,
    required this.moodBefore,
  });

  // ------------------------------------------------------------------
  // Serialization: Dart Object → Map (for SQLite INSERT / UPDATE)
  // ------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'checkin_time': checkinTime.toIso8601String(),
      'checkin_gps_lat': checkinGpsLat,
      'checkin_gps_lng': checkinGpsLng,
      'qr_code_checkin': qrCodeCheckin,
      'prev_topic': prevTopic,
      'expected_topic': expectedTopic,
      'mood_before': moodBefore,
    };
  }

  // ------------------------------------------------------------------
  // Deserialization: Map (from SQLite row) → Dart Object
  // ------------------------------------------------------------------
  factory CheckInRecord.fromMap(Map<String, dynamic> map) {
    return CheckInRecord(
      id: map['id'] as int?,
      studentId: map['student_id'] as String,
      checkinTime: DateTime.parse(map['checkin_time'] as String),
      checkinGpsLat: (map['checkin_gps_lat'] as num).toDouble(),
      checkinGpsLng: (map['checkin_gps_lng'] as num).toDouble(),
      qrCodeCheckin: map['qr_code_checkin'] as String,
      prevTopic: map['prev_topic'] as String,
      expectedTopic: map['expected_topic'] as String,
      moodBefore: map['mood_before'] as int,
    );
  }

  // ------------------------------------------------------------------
  // copyWith — convenient for updating specific fields
  // ------------------------------------------------------------------
  CheckInRecord copyWith({
    int? id,
    String? studentId,
    DateTime? checkinTime,
    double? checkinGpsLat,
    double? checkinGpsLng,
    String? qrCodeCheckin,
    String? prevTopic,
    String? expectedTopic,
    int? moodBefore,
  }) {
    return CheckInRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      checkinTime: checkinTime ?? this.checkinTime,
      checkinGpsLat: checkinGpsLat ?? this.checkinGpsLat,
      checkinGpsLng: checkinGpsLng ?? this.checkinGpsLng,
      qrCodeCheckin: qrCodeCheckin ?? this.qrCodeCheckin,
      prevTopic: prevTopic ?? this.prevTopic,
      expectedTopic: expectedTopic ?? this.expectedTopic,
      moodBefore: moodBefore ?? this.moodBefore,
    );
  }

  @override
  String toString() {
    return 'CheckInRecord('
        'id: $id, '
        'studentId: $studentId, '
        'checkinTime: $checkinTime, '
        'lat: $checkinGpsLat, '
        'lng: $checkinGpsLng, '
        'qrCode: $qrCodeCheckin, '
        'prevTopic: $prevTopic, '
        'expectedTopic: $expectedTopic, '
        'moodBefore: $moodBefore'
        ')';
  }
}
