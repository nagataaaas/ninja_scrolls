import 'dart:developer';

import 'package:data_size/data_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/database/sqlite.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/default_cache_manager_extention.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/wiki_index_provider.dart';
import 'package:ninja_scrolls/src/static/note_ids.dart';
import 'package:ninja_scrolls/src/view/components/show_platform_confirm_alert.dart';
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
  int? allTableCacheSize;
  int? readStateCacheSize;
  int? imageCacheSize;

  int? get allCacheSize => (allTableCacheSize != null && imageCacheSize != null)
      ? allTableCacheSize! + imageCacheSize!
      : null;

  late final indexProvider = context.read<EpisodeIndexProvider>();
  bool isIndexCacheLoading = true;
  DateTime? indexCachedAt;
  bool isWikiIndexCacheLoading = true;
  DateTime? wikiIndexCachedAt;

  @override
  void initState() {
    super.initState();
    reloadData();
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
          allTableCacheSize = value;
        }));
    ReadStateGateway.pgSize.then((value) => setState(() {
          readStateCacheSize = value;
        }));
    ReadStateGateway.pgSize.then((value) => setState(() {
          readStateCacheSize = value;
        }));
    DefaultCacheManagerExtention.instance.cacheSize.then((value) async {
      return setState(() {
        imageCacheSize = value;
      });
    });
    NoteGateway.cachedAt(NoteIds.toc).then((value) => setState(() {
          isIndexCacheLoading = false;
          indexCachedAt = value;
        }));
    WikiPageTableGateway.latestCreatedAt.then((value) => setState(() {
          isWikiIndexCacheLoading = false;
          wikiIndexCachedAt = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      contentPadding: EdgeInsetsDirectional.zero,
      lightTheme:
          context.watch<ThemeProvider>().lightTheme.theme.settingsThemeData,
      darkTheme:
          context.watch<ThemeProvider>().darkTheme.theme.settingsThemeData,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      sections: [
        SettingsSection(
          margin: EdgeInsetsDirectional.only(top: 16),
          title: GestureDetector(
              onLongPress: () async {
                log('delete database');
                await DatabaseHelper.instance.deleteDatabase();
                reloadData();
              },
              child: const Text('データキャッシュ')),
          tiles: <SettingsTile>[
            SettingsTile(
                title: const Text('全データ'),
                leading: const Icon(Icons.cached),
                onPressed: (context) async {
                  if (!await showPlatformConfirmAlert(
                      '全データキャッシュ削除${(allCacheSize?.formatByteSize()).parenthesize.nullToEmpty}',
                      '全てのデータが初期化されます。\nこの処理はやりなおすことができません。')) {
                    return;
                  }
                  await DatabaseHelper.instance.deleteAllTableData();
                  DefaultCacheManager().emptyCache();
                  reloadData();
                },
                trailing: Icon(Icons.delete_forever_outlined,
                    color: context.colorTheme.primary),
                value: allCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(allCacheSize!.formatByteSize())),
            SettingsTile(
                title: const Text('エピソードデータ'),
                leading: const Icon(Icons.cached),
                onPressed: (context) async {
                  if (!await showPlatformConfirmAlert(
                      'エピソードデータ削除${(episodesCacheSize?.formatByteSize()).parenthesize.nullToEmpty}',
                      '全てのエピソードのキャッシュが削除されます。\n閲覧状況はリセットされません。')) {
                    return;
                  }
                  await NoteGateway.deleteAll();
                  reloadData();
                },
                trailing: Icon(Icons.delete_forever_outlined,
                    color: context.colorTheme.primary),
                value: episodesCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(episodesCacheSize!.formatByteSize())),
            SettingsTile(
                title: const Text('閲覧状況データ'),
                leading: const Icon(Icons.cached),
                onPressed: (context) async {
                  if (!await showPlatformConfirmAlert(
                      '閲覧状況データ削除${(readStateCacheSize?.formatByteSize()).parenthesize.nullToEmpty}',
                      '全てのエピソードの閲覧状況・閲覧履歴がリセットされます。この処理はやりなおすことができません。')) {
                    return;
                  }
                  await ReadStateGateway.deleteAll();
                  await NoteGateway.resetRecentReadAt();
                  reloadData();
                },
                trailing: Icon(Icons.delete_forever_outlined,
                    color: context.colorTheme.primary),
                value: readStateCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(readStateCacheSize!.formatByteSize())),
            SettingsTile(
                title: const Text('画像データ'),
                leading: const Icon(Icons.cached),
                onPressed: (context) async {
                  if (!await showPlatformConfirmAlert(
                      '画像データ削除${(imageCacheSize?.formatByteSize()).parenthesize.nullToEmpty}',
                      '全てのエピソードの見出し画像キャッシュが削除されます。')) {
                    return;
                  }
                  await DefaultCacheManager().emptyCache();
                  reloadData();
                },
                trailing: Icon(Icons.delete_forever_outlined,
                    color: context.colorTheme.primary),
                value: imageCacheSize == null
                    ? const CircularProgressIndicator()
                    : Text(imageCacheSize!.formatByteSize()))
          ],
        ),
        SettingsSection(
          margin: EdgeInsetsDirectional.only(top: 16),
          title: const Text('目次キャッシュ'),
          tiles: [
            SettingsTile(
              title: Text(
                  '目次データ${indexProvider.index?.updatedAt == null ? '' : '(${dateFormat.format(indexProvider.index!.updatedAt!)}バージョン)'}'),
              leading: const Icon(Icons.cached),
              onPressed: (context) async {
                if (!await showPlatformConfirmAlert(
                    '目次キャッシュ再取得', '目次データを削除し、再取得します')) {
                  return;
                }
                setState(() {
                  indexCachedAt = null;
                  isIndexCacheLoading = true;
                });
                await indexProvider.refreshIndex();
                reloadData();

                if (!mounted) return;
              },
              trailing: Icon(Icons.delete_forever_outlined,
                  color: context.colorTheme.primary),
              value: isIndexCacheLoading
                  ? CircularProgressIndicator.adaptive()
                  : Text(indexCachedAt == null
                      ? '未キャッシュ'
                      : 'キャッシュ日時: ${timeFormat.format(indexCachedAt!.toLocal())}'),
            ),
            SettingsTile(
              title: Text('wikiページ一覧データ'),
              leading: const Icon(Icons.cached),
              onPressed: (context) async {
                if (!await showPlatformConfirmAlert('wikiページ一覧データ再取得',
                    'wikiのページ一覧データを再取得し、最新のページを検索できるようにします。\nこの処理は、検索履歴も初期化します。')) {
                  return;
                }
                setState(() {
                  wikiIndexCachedAt = null;
                  isWikiIndexCacheLoading = true;
                });
                await WikiPageTableGateway.deleteAll();
                if (!mounted) return;
                await context.read<WikiIndexProvider>().refreshWikiPages();
                reloadData();

                if (!mounted) return;
              },
              trailing: Icon(Icons.delete_forever_outlined,
                  color: context.colorTheme.primary),
              value: isWikiIndexCacheLoading
                  ? CircularProgressIndicator.adaptive()
                  : Text(wikiIndexCachedAt == null
                      ? '未キャッシュ'
                      : 'キャッシュ日時: ${timeFormat.format(wikiIndexCachedAt!.toLocal())}'),
            ),
          ],
        ),
      ],
    );
  }
}
