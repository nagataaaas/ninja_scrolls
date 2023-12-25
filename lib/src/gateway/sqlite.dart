import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

class Note {
  static const tableName = "episodes";

  final String id;
  final String title;
  final String html;

  Note({required this.id, required this.title, required this.html});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['key'],
      title: json['name'],
      html: json['body'],
    );
  }

  factory Note.fromDatabase(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      html: json['html'],
    );
  }

  static String createTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        html TEXT NOT NULL
      )
    ''';
  }
}

class DatabaseHelper {
  static const _databaseName = "DieHard.db";
  static const _databaseVersion = 1; // スキーマのバージョン指定

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = "${documentsDirectory.path}/$_databaseName";

    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(Note.createTableSql());
  }
}

// argument
//  - id: str
// returns:
//  bool: whether the episode is locally saved
Future<bool> isEpisodeCached(String id) async {
  var db = await DatabaseHelper.instance.database;
  var result =
      await db!.rawQuery("SELECT 1 FROM ${Note.tableName} WHERE id = ?", [id]);
  return result.isNotEmpty;
}

// argument
//  - episode: Episode
// returns:
//  bool: save episode to SQLite and return true
Future<bool> saveEpisode(Note episode) async {
  var db = await DatabaseHelper.instance.database;
  await db!.insert(Note.tableName, {
    'id': episode.id,
    'title': episode.title,
    'html': episode.html,
  });
  return true;
}

// argument
//  - id: str
// returns:
//  Episode: data of the episode
Future<Note> loadEpisode(String id) async {
  var db = await DatabaseHelper.instance.database;
  var result =
      await db!.query(Note.tableName, where: 'id = ?', whereArgs: [id]);
  return Note.fromDatabase(result.first);
}
