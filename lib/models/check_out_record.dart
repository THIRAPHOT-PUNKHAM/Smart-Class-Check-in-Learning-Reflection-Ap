// Data Model: CheckOutRecord
// Stores all check-out data captured AFTER class ends (Finish Class).
// Fields defined per PRD Section 5 — Data Fields.

class CheckOutRecord {
  final int? id; // Auto-increment primary key (SQLite)
  final int checkinId; // Foreign key → CheckInRecord.id (links the session)
  final DateTime checkoutTime; // Timestamp when Finish Class was pressed
  final double checkoutGpsLat; // Latitude captured at check-out
  final double checkoutGpsLng; // Longitude captured at check-out
  final String qrCodeCheckout; // QR code value scanned at check-out
  final String learnedToday; // What the student learned today (short text)
  final String feedback; // Feedback about the class / instructor

  const CheckOutRecord({
    this.id,
    required this.checkinId,
    required this.checkoutTime,
    required this.checkoutGpsLat,
    required this.checkoutGpsLng,
    required this.qrCodeCheckout,
    required this.learnedToday,
    required this.feedback,
  });

  // ------------------------------------------------------------------
  // Serialization: Dart Object → Map (for SQLite INSERT / UPDATE)
  // ------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'checkin_id': checkinId,
      'checkout_time': checkoutTime.toIso8601String(),
      'checkout_gps_lat': checkoutGpsLat,
      'checkout_gps_lng': checkoutGpsLng,
      'qr_code_checkout': qrCodeCheckout,
      'learned_today': learnedToday,
      'feedback': feedback,
    };
  }

  // ------------------------------------------------------------------
  // Deserialization: Map (from SQLite row) → Dart Object
  // ------------------------------------------------------------------
  factory CheckOutRecord.fromMap(Map<String, dynamic> map) {
    return CheckOutRecord(
      id: map['id'] as int?,
      checkinId: map['checkin_id'] as int,
      checkoutTime: DateTime.parse(map['checkout_time'] as String),
      checkoutGpsLat: (map['checkout_gps_lat'] as num).toDouble(),
      checkoutGpsLng: (map['checkout_gps_lng'] as num).toDouble(),
      qrCodeCheckout: map['qr_code_checkout'] as String,
      learnedToday: map['learned_today'] as String,
      feedback: map['feedback'] as String,
    );
  }

  // ------------------------------------------------------------------
  // copyWith — convenient for updating specific fields
  // ------------------------------------------------------------------
  CheckOutRecord copyWith({
    int? id,
    int? checkinId,
    DateTime? checkoutTime,
    double? checkoutGpsLat,
    double? checkoutGpsLng,
    String? qrCodeCheckout,
    String? learnedToday,
    String? feedback,
  }) {
    return CheckOutRecord(
      id: id ?? this.id,
      checkinId: checkinId ?? this.checkinId,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      checkoutGpsLat: checkoutGpsLat ?? this.checkoutGpsLat,
      checkoutGpsLng: checkoutGpsLng ?? this.checkoutGpsLng,
      qrCodeCheckout: qrCodeCheckout ?? this.qrCodeCheckout,
      learnedToday: learnedToday ?? this.learnedToday,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  String toString() {
    return 'CheckOutRecord('
        'id: $id, '
        'checkinId: $checkinId, '
        'checkoutTime: $checkoutTime, '
        'lat: $checkoutGpsLat, '
        'lng: $checkoutGpsLng, '
        'qrCode: $qrCodeCheckout, '
        'learnedToday: $learnedToday, '
        'feedback: $feedback'
        ')';
  }
}
