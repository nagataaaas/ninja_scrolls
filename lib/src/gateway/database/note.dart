import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';

class Note {
  final String id;
  final String title;
  final String html;
  final String? eyecatchUrl;
  final int remainedCharNum;
  final List<IndexItem> indexItems;
  final bool isLimited;
  final bool isPurchased;
  final BookPurchaseLink? bookPurchaseLink;
  final DateTime? cachedAt;
  DateTime? recentReadAt;

  Note({
    required this.id,
    required this.title,
    required this.html,
    this.eyecatchUrl,
    required this.remainedCharNum,
    this.indexItems = const [],
    required this.isLimited,
    required this.isPurchased,
    this.bookPurchaseLink,
    this.cachedAt,
    this.recentReadAt,
  });

  bool get canReadAll => !isLimited || isPurchased;

  List<IndexItem> get availableIndexItems {
    if (canReadAll) return indexItems;
    return indexItems
        .takeWhile((indexItem) => !RegExp(r'n-?files?', caseSensitive: false)
            .hasMatch(indexItem.title))
        .toList();
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['data']['key'],
      title: json['data']['name'],
      html: json['data']['body'] ?? '',
      eyecatchUrl: json['data']['eyecatch'],
      remainedCharNum: json['data']['remained_char_num'],
      indexItems: (json['data']['index'].cast<Map<String, dynamic>>())
          .map<IndexItem>((Map<String, dynamic> e) =>
              IndexItem(id: e['name'] as String, title: e['body'] as String))
          .toList()
          .cast<IndexItem>(),
      isLimited: json['data']['is_limited'],
      isPurchased: json['data']['is_purchased'],
      bookPurchaseLink: json['data']['embedded_contents'].length > 0
          ? BookPurchaseLink.fromJson(json['data']['embedded_contents'][0])
          : null,
      cachedAt: DateTime.now(),
    );
  }

  factory Note.fromDatabase(Map<String, Object?> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      html: json['html'] as String,
      eyecatchUrl: json['eyecatch_url'] as String,
      remainedCharNum: json['remained_char_num'] as int,
      indexItems:
          (jsonDecoder.convert(json['index_items'] as String).cast<String>())
              .map((e) => IndexItem.decode(e))
              .toList()
              .cast<IndexItem>(),
      isLimited: json['is_limited'] != 0,
      isPurchased: false,
      bookPurchaseLink: json['book_purchase_link'] == null
          ? null
          : BookPurchaseLink.fromDatabase(json['book_purchase_link'] as String),
      cachedAt: DateTime.parse(json['cached_at'] as String),
      recentReadAt: json['recent_read_at'] == null
          ? null
          : DateTime.parse(json['recent_read_at'] as String),
    );
  }
}

class NoteGateway {
  static const tableName = "notes";

  static String createTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        html TEXT NOT NULL,
        eyecatch_url TEXT,
        remained_char_num INTEGER NOT NULL,
        index_items INTEGER NOT NULL,
        is_limited INTEGER NOT NULL,
        is_purchased INTEGER NOT NULL,
        book_purchase_link TEXT,
        cached_at TEXT NOT NULL,
        recent_read_at TEXT
      );
      CREATE INDEX IF NOT EXISTS ${tableName}_recent_read_at ON $tableName (recent_read_at);
    ''';
  }

  static String get pgSizeSql =>
      'SELECT SUM("pgsize") FROM "dbstat" WHERE name="$tableName";';

  // argument
  //  - id: str
  // returns:
  //  bool: whether the note is locally saved
  static Future<bool> isCached(String id) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // argument
  //  - id: str
  // returns:
  //  datetime: when the note is saved
  static Future<DateTime?> cachedAt(String id) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return DateTime.parse(result.first['cached_at'] as String);
  }

  // argument
  //  - note: Note
  // returns:
  //  bool: save note to SQLite and return true
  static Future<bool> save(Note note) async {
    var db = await DatabaseHelper.instance.database;
    if (await isCached(note.id)) {
      await db!.update(
          tableName,
          {
            'title': note.title,
            'html': note.html,
            'eyecatch_url': note.eyecatchUrl,
            'remained_char_num': note.remainedCharNum,
            'index_items': jsonEncoder
                .convert(note.indexItems.map((e) => e.encode()).toList()),
            'is_limited': note.isLimited ? 1 : 0,
            'is_purchased': note.isPurchased ? 1 : 0,
            'book_purchase_link': note.bookPurchaseLink?.encode(),
            'cached_at': DateTime.now().toIso8601String(),
            'recent_read_at': note.recentReadAt?.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [note.id]);
      return true;
    }
    await db!.insert(tableName, {
      'id': note.id,
      'title': note.title,
      'html': note.html,
      'eyecatch_url': note.eyecatchUrl,
      'remained_char_num': note.remainedCharNum,
      'index_items':
          jsonEncoder.convert(note.indexItems.map((e) => e.encode()).toList()),
      'is_limited': note.isLimited ? 1 : 0,
      'is_purchased': note.isPurchased ? 1 : 0,
      'book_purchase_link': note.bookPurchaseLink?.encode(),
      'cached_at': DateTime.now().toIso8601String(),
      'recent_read_at': note.recentReadAt?.toIso8601String(),
    });
    return true;
  }

  static Future<List<Note>> recentRead(int count) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName,
        where: 'recent_read_at IS NOT NULL',
        orderBy: 'recent_read_at DESC',
        limit: count);
    return result.map((e) => Note.fromDatabase(e)).toList();
  }

  static Future resetRecentReadAt() async {
    var db = await DatabaseHelper.instance.database;
    await db!.update(tableName, {'recent_read_at': null});
  }

  // argument
  //  - id: str
  // returns:
  //  Note: data of the note
  static Future<Note> load(String id) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return Note.fromDatabase(result.first);
  }

  static Future<int> get pgSize async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.rawQuery(pgSizeSql);
    return result.first.values.first as int;
  }

  static Future<void> deleteAll() async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(tableName);
  }

  static Future<void> delete(String id) async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
