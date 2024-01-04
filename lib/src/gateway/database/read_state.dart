import 'package:html/parser.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';

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

enum ReadState { notRead, reading, read }

class ReadStatus {
  final ReadState state;
  final double readProgress;

  ReadStatus({required this.state, required this.readProgress});

  factory ReadStatus.fromDatabase(Map<String, dynamic> json) {
    return ReadStatus(
      state: json['is_completed'] == 1 ? ReadState.read : ReadState.reading,
      readProgress: (json['read_progress'] / ReadStateGateway.realToInteger),
    );
  }

  factory ReadStatus.zero() {
    return ReadStatus(state: ReadState.notRead, readProgress: 0);
  }
}

class ReadStateGateway {
  static const tableName = "read_states";
  static const realToInteger = 1000;

  static String createTableSql() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        note_id TEXT PRIMARY KEY,
        is_completed INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        read_progress INTEGER NOT NULL DEFAULT 0,
        foreign key (note_id) references ${NoteGateway.tableName}(id)
      )
    ''';
  }

  static String get pgSizeSql =>
      'SELECT SUM("pgsize") FROM "dbstat" WHERE name="$tableName";';

  static Future<Map<String, ReadStatus>> getStatus(List<String> noteIds) async {
    var db = await DatabaseHelper.instance.database;
    var result = await db!.query(tableName,
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
    final isRecordExists = await db!
        .rawQuery("SELECT 1 FROM $tableName WHERE note_id = ?", [noteId]);
    if (isRecordExists.isNotEmpty) {
      await db.update(
          tableName,
          {
            'is_completed': state == ReadState.read ? 1 : 0,
            'read_progress': (readProgress * realToInteger).toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'note_id = ?',
          whereArgs: [noteId]);
    } else {
      await db.insert(tableName, {
        'note_id': noteId,
        'is_completed': state == ReadState.read ? 1 : 0,
        'read_progress': (readProgress * realToInteger).toInt(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
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
}
