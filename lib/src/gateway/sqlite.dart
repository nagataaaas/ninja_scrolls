import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:html/parser.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

final jsonEncoder = JsonEncoder();
final jsonDecoder = JsonDecoder();

class IndexItem {
  final String id;
  final String title;

  IndexItem({required this.id, required this.title});

  String encode() {
    return jsonEncoder.convert({
      "id": id,
      "title": title,
    });
  }

  static IndexItem decode(String input) {
    final objects = jsonDecoder.convert(input);
    return IndexItem(
      id: objects['id']!,
      title: objects['title']!,
    );
  }
}

class BookPurchaseLink {
  final String title;
  final String price;
  final String url;
  final String? imageUrl;

  BookPurchaseLink({
    required this.title,
    required this.price,
    required this.url,
    required this.imageUrl,
  });

  factory BookPurchaseLink.fromJson(Map<String, dynamic> json) {
    final html = json['html_for_embed'] as String;
    final document = parse(html);

    final title = document
            .querySelector('strong.external-article-widget-title')
            ?.text
            .trim() ??
        '';
    final price = document
            .querySelector('em.external-article-widget-regularprice')
            ?.text
            .trim() ??
        '';
    final imageUrlMatches = RegExp(r"background-image: url\('?(.+?)'?\);")
        .allMatches(document
                .querySelector('a.external-article-widget-image')
                ?.outerHtml ??
            '');
    final imageUrl =
        imageUrlMatches.isEmpty ? '' : imageUrlMatches.first.group(1);

    return BookPurchaseLink(
      title: title,
      price: price,
      url: json['url'] as String,
      imageUrl: imageUrl,
    );
  }

  factory BookPurchaseLink.fromDatabase(String json) {
    final objects = jsonDecoder.convert(json);
    return BookPurchaseLink(
      title: objects['title']!,
      price: objects['price']!,
      url: objects['url']!,
      imageUrl: objects['imageUrl'],
    );
  }

  String encode() {
    return jsonEncoder.convert({
      "title": title,
      "price": price,
      "url": url,
      "imageUrl": imageUrl,
    });
  }
}

class Note {
  static const tableName = "notes";

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
    );
  }

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
        cached_at TEXT NOT NULL
      )
    ''';
  }

  static String get pgSizeSql =>
      'SELECT SUM("pgsize") FROM "dbstat" WHERE name="$tableName";';
}

enum ReadState { notRead, reading, read }

class ReadStatus {
  final ReadState state;
  final double readProgress;

  ReadStatus({required this.state, required this.readProgress});

  factory ReadStatus.fromDatabase(Map<String, dynamic> json) {
    return ReadStatus(
      state: json['is_completed'] == 1 ? ReadState.read : ReadState.reading,
      readProgress: (json['read_progress'] / ReadStateTable.realToInteger),
    );
  }

  factory ReadStatus.zero() {
    return ReadStatus(state: ReadState.notRead, readProgress: 0);
  }
}

class ReadStateTable {
  static const tableName = "read_states";
  static const realToInteger = 1000;

  static String createTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        note_id TEXT PRIMARY KEY,
        is_completed INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        read_progress INTEGER NOT NULL DEFAULT 0,
        foreign key (note_id) references ${Note.tableName}(id)
      )
    ''';
  }

  static String get pgSizeSql =>
      'SELECT SUM("pgsize") FROM "dbstat" WHERE name="$tableName";';
}

class DatabaseHelper {
  static const _databaseName = "DieHard.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  late String _path;

  Future<void> ensurePathInitialized() async {
    if (_database != null) return;

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _path = pathlib.join(appDocumentsDir.path, "databases", _databaseName);
  }

  Future<Database?> get database async {
    await ensurePathInitialized();
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
    await db.execute(Note.createTableSql());
    await db.execute(ReadStateTable.createTableSql());
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
    await db!.delete(Note.tableName);
    await db.delete(ReadStateTable.tableName);
  }

  Future<int> get pgSize async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.rawQuery('SELECT SUM("pgsize") FROM "dbstat";');
    return result.first.values.first as int;
  }
}

class NoteGateway {
  // argument
  //  - id: str
  // returns:
  //  bool: whether the note is locally saved
  static Future<bool> isCached(String id) async {
    log('isCached: $id');
    var db = await DatabaseHelper.instance.database;
    var result =
        await db!.query(Note.tableName, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // argument
  //  - id: str
  // returns:
  //  datetime: when the note is saved
  static Future<DateTime?> cachedAt(String id) async {
    log('cachedAt: $id');
    var db = await DatabaseHelper.instance.database;
    var result =
        await db!.query(Note.tableName, where: 'id = ?', whereArgs: [id]);
    print(result.first);
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
          Note.tableName,
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
          },
          where: 'id = ?',
          whereArgs: [note.id]);
      return true;
    }
    await db!.insert(Note.tableName, {
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
    });
    return true;
  }

  // argument
  //  - id: str
  // returns:
  //  Note: data of the note
  static Future<Note> load(String id) async {
    var db = await DatabaseHelper.instance.database;
    var result =
        await db!.query(Note.tableName, where: 'id = ?', whereArgs: [id]);
    return Note.fromDatabase(result.first);
  }

  static Future<int> get pgSize async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.rawQuery(Note.pgSizeSql);
    return result.first.values.first as int;
  }

  static Future<void> deleteAll() async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(Note.tableName);
  }

  static Future<void> delete(String id) async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(Note.tableName, where: 'id = ?', whereArgs: [id]);
  }
}

class ReadStateGateway {
  static Future<Map<String, ReadStatus>> getStatus(List<String> noteIds) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(ReadStateTable.tableName,
        where: 'note_id IN (${noteIds.map((e) => '?').join(',')})',
        whereArgs: noteIds);
    final Map<String, ReadStatus> statusByNoteId = {};
    for (var row in result) {
      statusByNoteId[row['note_id'] as String] = ReadStatus.fromDatabase(row);
    }
    for (var noteId in noteIds) {
      if (!statusByNoteId.containsKey(noteId)) {
        statusByNoteId[noteId] = ReadStatus.zero();
      }
    }
    return statusByNoteId;
  }

  static Future<void> updateStatus(
      String noteId, ReadState state, double? readProgress) async {
    if (readProgress == null || readProgress.isNaN) {
      readProgress = 0.0;
    } else if (readProgress > 1.0 || readProgress.isInfinite) {
      readProgress = 1.0;
    }
    var db = await DatabaseHelper.instance.database;
    final isRecordExists = await db!.rawQuery(
        "SELECT 1 FROM ${ReadStateTable.tableName} WHERE note_id = ?",
        [noteId]);
    if (isRecordExists.isNotEmpty) {
      await db.update(
          ReadStateTable.tableName,
          {
            'is_completed': state == ReadState.read ? 1 : 0,
            'read_progress':
                (readProgress * ReadStateTable.realToInteger).toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'note_id = ?',
          whereArgs: [noteId]);
    } else {
      await db.insert(ReadStateTable.tableName, {
        'note_id': noteId,
        'is_completed': state == ReadState.read ? 1 : 0,
        'read_progress': (readProgress * ReadStateTable.realToInteger).toInt(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<int> get pgSize async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.rawQuery(ReadStateTable.pgSizeSql);
    return result.first.values.first as int;
  }

  static Future<void> deleteAll() async {
    var db = await DatabaseHelper.instance.database;
    await db!.delete(ReadStateTable.tableName);
  }
}
