import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';

class WikiPage {
  final String title;
  final String endpoint;
  WikiPage({
    required this.title,
    required this.endpoint,
  });

  String get url => '${WikiNetworkGateway.baseUrl}$endpoint';

  factory WikiPage.fromDatabase(Map<String, dynamic> json) {
    return WikiPage(
      title: json['title'] as String,
      endpoint: json['endpoint'] as String,
    );
  }
}

class WikiPageTableGateway {
  static const tableName = "wiki_pages";

  static String createTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        title TEXT PRIMARY KEY,
        endpoint TEXT NOT NULL,
        last_accessed_at TEXT,
        created_at TEXT NOT NULL
      );
      CREATE INDEX IF NOT EXISTS created_at_index ON $tableName(created_at);
      CREATE INDEX IF NOT EXISTS last_accessed_at_index ON $tableName(last_accessed_at);
    ''';
  }

  static String get pgSizeSql =>
      'SELECT SUM("pgsize") FROM "dbstat" WHERE name="$tableName";';

  static Future<bool> get isCached async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName, limit: 1);
    return result.isNotEmpty;
  }

  static Future<List<WikiPage>> get all async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName);
    return result.map((e) => WikiPage.fromDatabase(e)).toList();
  }

  static Future<DateTime?> get latestCreatedAt async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.rawQuery(
      'SELECT MAX(created_at) FROM $tableName',
    );
    if (result.isEmpty) return null;
    return DateTime.parse(result.first.values.first as String);
  }

  static Future<void> save(List<WikiPage> pages) async {
    var db = await DatabaseHelper.instance.database;
    final createdAt = DateTime.now().toIso8601String();
    await db!.transaction((txn) async {
      for (var page in pages) {
        await txn.insert(tableName, {
          'title': page.title,
          'endpoint': page.endpoint,
          'created_at': createdAt,
        });
      }
    });
  }

  static Future<List<WikiPage>> recentAccessed(int limit) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(
      tableName,
      orderBy: 'last_accessed_at DESC',
      limit: limit,
      where: 'last_accessed_at IS NOT NULL',
    );
    return result.map((e) => WikiPage.fromDatabase(e)).toList();
  }

  static Future<void> updateLastAccessedAt(String title) async {
    var db = await DatabaseHelper.instance.database;
    await db!.update(
      tableName,
      {
        'last_accessed_at': DateTime.now().toIso8601String(),
      },
      where: 'title = ?',
      whereArgs: [title],
    );
  }

  static Future<void> removeAccessedAt(String title) async {
    var db = await DatabaseHelper.instance.database;
    await db!.update(
      tableName,
      {
        'last_accessed_at': null,
      },
      where: 'title = ?',
      whereArgs: [title],
    );
  }

  static Future<void> deleteAll() async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(tableName);
  }
}
