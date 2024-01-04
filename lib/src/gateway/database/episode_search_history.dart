import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';

class InputHistoryData {
  String value;
  DateTime createdAt;

  InputHistoryData({required this.value, required this.createdAt});

  factory InputHistoryData.fromDatabase(Map<String, Object?> json) {
    return InputHistoryData(
      value: json['value'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String toJson() => jsonEncoder.convert({
        'value': value,
        'created_at': createdAt.toIso8601String(),
      });
}

class EpisodeSearchHistoryGateway {
  static const tableName = "episode_search_history";
  static const int limit = 30;

  static String createTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        created_at TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''';
  }

  static Future<List<InputHistoryData>> get all async {
    final db = await DatabaseHelper.instance.database;
    final result = await db!.query(tableName, orderBy: 'created_at DESC');
    return result.map((e) => InputHistoryData.fromDatabase(e)).toList();
  }

  static Future<void> addOrTouch(String data) async {
    final db = await DatabaseHelper.instance.database;
    final exists =
        await db!.query(tableName, where: 'value = ?', whereArgs: [data]);
    if (exists.isNotEmpty) {
      await db.update(
          tableName,
          {
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'value = ?',
          whereArgs: [data]);
      return;
    }

    await db.insert(tableName, {
      'created_at': DateTime.now().toIso8601String(),
      'value': data,
    });
    final count = await db.rawQuery(
        'SELECT created_at FROM $tableName ORDER BY created_at DESC LIMIT 1 OFFSET $limit');
    if (count.isNotEmpty) {
      await db.delete(tableName,
          where: 'created_at < ?', whereArgs: [count.first['created_at']]);
    }
  }

  static Future<void> remove(String data) async {
    final db = await DatabaseHelper.instance.database;
    await db!.delete(tableName, where: 'value = ?', whereArgs: [data]);
  }

  static String get pgSizeSql =>
      'SELECT SUM("pgsize") FROM "dbstat" WHERE name="$tableName";';

  static Future<int> get pgSize async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.rawQuery(pgSizeSql);
    return result.first.values.first as int;
  }

  static Future<void> deleteAll() async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(tableName);
  }
}
