import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/check_in_record.dart';
import '../models/check_out_record.dart';

/// DatabaseService
/// ---------------
/// Singleton service that manages the local SQLite database.
/// Uses the sqflite package to persist CheckInRecord and CheckOutRecord data.
///
/// Usage:
///   final db = DatabaseService.instance;
///   final id = await db.insertCheckIn(record);
///   final records = await db.getAllCheckIns();

class DatabaseService {
  // ------------------------------------------------------------------
  // Singleton setup
  // ------------------------------------------------------------------
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;

  // Database file name and version
  static const String _dbName = 'smart_class_checkin.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _tableCheckIn = 'check_in_records';
  static const String _tableCheckOut = 'check_out_records';

  // ------------------------------------------------------------------
  // Get (or create) the database
  // ------------------------------------------------------------------
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // ------------------------------------------------------------------
  // Create tables on first launch
  // ------------------------------------------------------------------
  Future<void> _onCreate(Database db, int version) async {
    // check_in_records table
    await db.execute('''
      CREATE TABLE $_tableCheckIn (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id      TEXT    NOT NULL,
        checkin_time    TEXT    NOT NULL,
        checkin_gps_lat REAL    NOT NULL,
        checkin_gps_lng REAL    NOT NULL,
        qr_code_checkin TEXT    NOT NULL,
        prev_topic      TEXT    NOT NULL,
        expected_topic  TEXT    NOT NULL,
        mood_before     INTEGER NOT NULL
      )
    ''');

    // check_out_records table
    await db.execute('''
      CREATE TABLE $_tableCheckOut (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        checkin_id        INTEGER NOT NULL,
        checkout_time     TEXT    NOT NULL,
        checkout_gps_lat  REAL    NOT NULL,
        checkout_gps_lng  REAL    NOT NULL,
        qr_code_checkout  TEXT    NOT NULL,
        learned_today     TEXT    NOT NULL,
        feedback          TEXT    NOT NULL,
        FOREIGN KEY (checkin_id) REFERENCES $_tableCheckIn(id) ON DELETE CASCADE
      )
    ''');
  }

  // ====================================================================
  //  CHECK-IN  CRUD
  // ====================================================================

  /// INSERT a new check-in record.
  /// Returns the row id assigned by SQLite.
  Future<int> insertCheckIn(CheckInRecord record) async {
    final db = await database;
    return db.insert(
      _tableCheckIn,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// SELECT all check-in records, newest first.
  Future<List<CheckInRecord>> getAllCheckIns() async {
    final db = await database;
    final maps = await db.query(
      _tableCheckIn,
      orderBy: 'checkin_time DESC',
    );
    return maps.map(CheckInRecord.fromMap).toList();
  }

  /// SELECT a single check-in record by id.
  Future<CheckInRecord?> getCheckInById(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableCheckIn,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CheckInRecord.fromMap(maps.first);
  }

  /// UPDATE an existing check-in record.
  /// Returns the number of rows affected.
  Future<int> updateCheckIn(CheckInRecord record) async {
    if (record.id == null) {
      throw ArgumentError('Cannot update a CheckInRecord without an id.');
    }
    final db = await database;
    return db.update(
      _tableCheckIn,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// DELETE a check-in record by id (cascades to its check-out record).
  /// Returns the number of rows affected.
  Future<int> deleteCheckIn(int id) async {
    final db = await database;
    return db.delete(
      _tableCheckIn,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================================================================
  //  CHECK-OUT  CRUD
  // ====================================================================

  /// INSERT a new check-out record.
  /// Returns the row id assigned by SQLite.
  Future<int> insertCheckOut(CheckOutRecord record) async {
    final db = await database;
    return db.insert(
      _tableCheckOut,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// SELECT all check-out records, newest first.
  Future<List<CheckOutRecord>> getAllCheckOuts() async {
    final db = await database;
    final maps = await db.query(
      _tableCheckOut,
      orderBy: 'checkout_time DESC',
    );
    return maps.map(CheckOutRecord.fromMap).toList();
  }

  /// SELECT the check-out record linked to a specific check-in id.
  Future<CheckOutRecord?> getCheckOutByCheckinId(int checkinId) async {
    final db = await database;
    final maps = await db.query(
      _tableCheckOut,
      where: 'checkin_id = ?',
      whereArgs: [checkinId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CheckOutRecord.fromMap(maps.first);
  }

  /// UPDATE an existing check-out record.
  /// Returns the number of rows affected.
  Future<int> updateCheckOut(CheckOutRecord record) async {
    if (record.id == null) {
      throw ArgumentError('Cannot update a CheckOutRecord without an id.');
    }
    final db = await database;
    return db.update(
      _tableCheckOut,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// DELETE a check-out record by id.
  /// Returns the number of rows affected.
  Future<int> deleteCheckOut(int id) async {
    final db = await database;
    return db.delete(
      _tableCheckOut,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================================================================
  //  Utility
  // ====================================================================

  /// Close the database connection (call this only when you know the app
  /// is shutting down and will not need the DB again).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
