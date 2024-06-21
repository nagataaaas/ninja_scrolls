import 'dart:developer';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class DefaultCacheManagerExtention {
  static const _databaseName = DefaultCacheManager.key;

  DefaultCacheManagerExtention._privateConstructor();
  static final DefaultCacheManagerExtention instance =
      DefaultCacheManagerExtention._privateConstructor();

  static Database? _database;
  late String _path;

  Future<void> ensureInitialized() async {
    if (_database != null) return;
    if (Platform.isWindows || Platform.isLinux) {
      sqflite_ffi.sqfliteFfiInit();
    }

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _path = join(appDocumentsDir.path, "databases", _databaseName);
  }

  Future<bool> databaseExists() async {
    if (Platform.isWindows || Platform.isLinux) {
      return sqflite_ffi.databaseFactoryFfi.databaseExists(_path);
    }
    return databaseFactory.databaseExists(_path);
  }

  Future<Database?> get database async {
    await ensureInitialized();

    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      return await sqflite_ffi.databaseFactoryFfi.openDatabase(_path);
    }

    return await openDatabase(_path);
  }

  Future<int> get pgSize async {
    var db = await instance.database;
    var result = await db!.rawQuery('SELECT SUM("pgsize") FROM "dbstat";');
    return result.first.values.first as int;
  }

  Future<List<String>> listDirTemporaryDirectory() async {
    final dir = await getTemporaryDirectory();
    final files = await dir.list().toList();
    return files.map((e) => e.path).toList();
  }

  Future<int> get cacheSize async {
    final dir = (await getTemporaryDirectory());
    int totalSize = 0;
    try {
      totalSize += await instance.databaseExists() ? await instance.pgSize : 0;
    } catch (e) {
      log(e.toString());
    }

    final databaseDir = Directory(join(dir.path, _databaseName));
    try {
      if (databaseDir.existsSync()) {
        databaseDir
            .listSync(recursive: true, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      log(e.toString());
    }
    return totalSize;
  }
}
