import 'dart:developer';

import 'package:data_size/data_size.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ninja_scrolls/src/gateway/sqlite.dart';
import 'package:ninja_scrolls/src/providers/index_provider.dart';
import 'package:ninja_scrolls/src/static/note_ids.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

final dateFormat = DateFormat('yyyy/MM/dd');
final timeFormat = DateFormat('yyyy/MM/dd HH:mm:ss');

class SettingsDataView extends StatefulWidget {
  const SettingsDataView({super.key});

  @override
  State<SettingsDataView> createState() => _SettingsDataViewState();
}

class _SettingsDataViewState extends State<SettingsDataView> {
  int? episodesCacheSize;
  int? allCacheSize;
  int? readStateCacheSize;

  late final indexProvider = context.read<IndexProvider>();
  bool isIndexCacheLoading = true;
  DateTime? indexCachedAt;

  @override
  void initState() {
    super.initState();
    NoteGateway.pgSize.then((value) => setState(() {
          episodesCacheSize = value;
        }));
    DatabaseHelper.instance.pgSize.then((value) => setState(() {
          allCacheSize = value;
        }));
    ReadStateGateway.pgSize.then((value) => setState(() {
          readStateCacheSize = value;
        }));
    NoteGateway.cachedAt(NoteIds.toc).then((value) => setState(() {
          indexCachedAt = value;
          isIndexCacheLoading = false;
        }));
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    reloadData();
  }

  void reloadData() {
    NoteGateway.pgSize.then((value) => setState(() {
          episodesCacheSize = value;
        }));
    DatabaseHelper.instance.pgSize.then((value) => setState(() {
          allCacheSize = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      sections: [
        SettingsSection(
          title: GestureDetector(
              onLongPress: () async {
                log('delete database');
                await DatabaseHelper.instance.deleteDatabase();
                reloadData();
              },
              child: const Text('データキャッシュ')),
          tiles: <SettingsTile>[
            SettingsTile(
                onPressed: (context) async {
                  await DatabaseHelper.instance.deleteAllTableData();
                  reloadData();
                },
                leading: const Icon(Icons.cached),
                title: const Text('全データ'),
                trailing: const Icon(Icons.delete_forever_outlined),
                value: allCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(allCacheSize!.formatByteSize())),
            SettingsTile(
                onPressed: (context) async {
                  await NoteGateway.deleteAll();
                  reloadData();
                },
                leading: const Icon(Icons.cached),
                title: const Text('エピソードデータ'),
                trailing: const Icon(Icons.delete_forever_outlined),
                value: episodesCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(episodesCacheSize!.formatByteSize())),
            SettingsTile(
                onPressed: (context) async {
                  await ReadStateGateway.deleteAll();
                  reloadData();
                },
                leading: const Icon(Icons.cached),
                title: const Text('閲覧状況データ'),
                trailing: const Icon(Icons.delete_forever_outlined),
                value: readStateCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(readStateCacheSize!.formatByteSize()))
          ],
        ),
        SettingsSection(
          title: const Text('目次キャッシュ'),
          tiles: [
            SettingsTile(
              onPressed: (context) async {
                setState(() {
                  indexCachedAt = null;
                  isIndexCacheLoading = true;
                });
                await indexProvider.refreshIndex();
                NoteGateway.cachedAt(NoteIds.toc).then((value) => setState(() {
                      indexCachedAt = value;
                      isIndexCacheLoading = false;
                    }));
                if (!mounted) return;
              },
              leading: const Icon(Icons.cached),
              title: Text(
                  '目次データ${indexProvider.index?.updatedAt == null ? '' : '(${dateFormat.format(indexProvider.index!.updatedAt!)}バージョン)'}'),
              trailing: const Icon(Icons.delete_forever_outlined),
              value: isIndexCacheLoading
                  ? CircularProgressIndicator.adaptive()
                  : Text(indexCachedAt == null
                      ? '未キャッシュ'
                      : 'キャッシュ日時: ${timeFormat.format(indexCachedAt!.toLocal())}'),
            ),
          ],
        )
      ],
    );
  }
}
