import 'package:ninja_scrolls/src/gateway/database/episode_search_history.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Database? _testDb;

Future<void> setupTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1),
  );

  // NoteGateway and WikiPageTableGateway have multi-statement SQL,
  // so we split by ';' and execute each statement individually.
  for (final sql in _splitSql(NoteGateway.createTableSql())) {
    await db.execute(sql);
  }
  for (final sql in _splitSql(ReadStateGateway.createTableSql())) {
    await db.execute(sql);
  }
  for (final sql in _splitSql(EpisodeSearchHistoryGateway.createTableSql())) {
    await db.execute(sql);
  }
  for (final sql in _splitSql(WikiPageTableGateway.createTableSql())) {
    await db.execute(sql);
  }

  _testDb = db;
  DatabaseHelper.testDatabase = db;
}

Future<void> tearDownTestDatabase() async {
  final db = _testDb;
  _testDb = null;
  DatabaseHelper.testDatabase = null;
  if (db != null && db.isOpen) {
    await db.close();
  }
}

List<String> _splitSql(String sql) {
  return sql
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
