import 'dart:convert';
import 'dart:io';

import 'package:ninja_scrolls/src/gateway/database/episode_search_history.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

final jsonEncoder = JsonEncoder();
final jsonDecoder = JsonDecoder();

class DatabaseHelper {
  static const _databaseName = "DieHard.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  late String _path;

  Future<void> ensureInitialized() async {
    if (_database != null) return;

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _path = join(appDocumentsDir.path, "databases", _databaseName);
  }

  Future<Database?> get database async {
    if (_database != null) return _database;

    await ensureInitialized();
    if (Platform.isWindows || Platform.isLinux) {
      sqflite_ffi.sqfliteFfiInit();
    }
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      final db = await sqflite_ffi.databaseFactoryFfi.openDatabase(_path,
          options: OpenDatabaseOptions(
            version: _databaseVersion,
            onOpen: _onOpen,
          ));
      return db;
    }

    return await openDatabase(_path,
        version: _databaseVersion, onOpen: _onOpen);
  }

  Future _onOpen(Database db, [int? version]) async {
    await db.execute(NoteGateway.createTableSql());
    await db.execute(ReadStateGateway.createTableSql());
    await db.execute(EpisodeSearchHistoryGateway.createTableSql());
    await db.execute(WikiPageTableGateway.createTableSql());
  }

  Future deleteDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      await sqflite_ffi.databaseFactoryFfi.deleteDatabase(_path);
    } else {
      await databaseFactory.deleteDatabase(_path);
    }
    _database = null;
  }

  Future deleteAllTableData() async {
    final db = await database;
    await db!.delete(NoteGateway.tableName);
    await db.delete(ReadStateGateway.tableName);
  }

  Future<int> get pgSize async {
    var db = await instance.database;
    var result = await db!.rawQuery('SELECT SUM("pgsize") FROM "dbstat";');
    return result.first.values.first as int;
  }
}
