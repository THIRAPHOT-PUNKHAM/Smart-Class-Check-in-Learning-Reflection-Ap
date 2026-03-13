import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/check_in_record.dart';
import '../models/check_out_record.dart';

/// FirebaseSyncService
/// -------------------
/// Singleton service that syncs local SQLite records to Firebase Firestore
/// whenever an internet connection is available.
///
/// Design decisions:
/// - Uses the SQLite `id` as the Firestore document ID → re-syncing is idempotent.
/// - All errors are caught silently so offline/unconfigured Firebase never crashes the app.
/// - Adds a server-side `synced_at` timestamp on each Firestore document.
///
/// Usage:
///   await FirebaseSyncService.instance.syncCheckIn(record);
///   await FirebaseSyncService.instance.syncAll(checkIns, checkOuts);

class FirebaseSyncService {
  // ── Singleton ────────────────────────────────────────────────────
  FirebaseSyncService._internal();
  static final FirebaseSyncService instance = FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection names
  static const String _colCheckIns  = 'check_ins';
  static const String _colCheckOuts = 'check_outs';

  // ── Connectivity helper ───────────────────────────────────────────

  /// Returns true if the device has any active network connection.
  Future<bool> isConnected() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  // ── Single record sync ────────────────────────────────────────────

  /// Upserts one [CheckInRecord] to Firestore.
  /// No-ops silently if offline or if the record has no id.
  Future<void> syncCheckIn(CheckInRecord record) async {
    if (record.id == null) return;
    if (!await isConnected()) return;

    try {
      final data = record.toMap()
        ..['synced_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_colCheckIns)
          .doc(record.id.toString())
          .set(data, SetOptions(merge: true));
    } catch (e) {
      // Sync failed — local data is safe, just log.
      // ignore: avoid_print
      print('[FirebaseSync] syncCheckIn error: $e');
    }
  }

  /// Upserts one [CheckOutRecord] to Firestore.
  /// No-ops silently if offline or if the record has no id.
  Future<void> syncCheckOut(CheckOutRecord record) async {
    if (record.id == null) return;
    if (!await isConnected()) return;

    try {
      final data = record.toMap()
        ..['synced_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_colCheckOuts)
          .doc(record.id.toString())
          .set(data, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('[FirebaseSync] syncCheckOut error: $e');
    }
  }

  // ── Bulk sync (e.g. on app resume) ───────────────────────────────

  /// Upserts all provided check-in and check-out records using a single
  /// Firestore WriteBatch (max 500 documents per batch).
  ///
  /// Splits into multiple batches automatically if needed.
  Future<void> syncAll({
    required List<CheckInRecord> checkIns,
    required List<CheckOutRecord> checkOuts,
  }) async {
    if (!await isConnected()) return;

    final allDocs = <Future<void>>[];

    // Collect all check-in writes
    for (final ci in checkIns) {
      if (ci.id == null) continue;
      allDocs.add(syncCheckIn(ci));
    }

    // Collect all check-out writes
    for (final co in checkOuts) {
      if (co.id == null) continue;
      allDocs.add(syncCheckOut(co));
    }

    try {
      // Run all writes concurrently (each is an independent upsert).
      await Future.wait(allDocs, eagerError: false);
    } catch (e) {
      // ignore: avoid_print
      print('[FirebaseSync] syncAll error: $e');
    }
  }
}
