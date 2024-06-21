import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/episode_search_history.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/create_loading_indicator_on_setting.dart';
import 'package:provider/provider.dart';

class EpisodeSearchView extends StatefulWidget {
  const EpisodeSearchView({super.key});

  @override
  State<EpisodeSearchView> createState() => _EpisodeSearchViewState();
}

class _EpisodeSearchViewState extends State<EpisodeSearchView> {
  late final TextEditingController _searchTextController;
  List<InputHistoryData> _histories = [];
  Map<Chapter, List<EpisodeLink>> _searchResultMap = {};
  Map<String, ReadStatus> episodeStatus = {};
  late final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchTextController = TextEditingController()
      ..addListener(onSearchQueryChanged);
    EpisodeSearchHistoryGateway.all.then((value) {
      setState(() {
        _histories = value;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<ScaffoldProvider>().episodeSearchAppBar = appBar;
    });
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    context.read<ScaffoldProvider>().episodeSearchAppBar = null;
    super.dispose();
  }

  void onSearchQueryChanged() {
    scrollController.jumpTo(0);
    setState(() {
      _searchResultMap = search(_searchTextController.text);
    });
    updateEpisodeStatus();
  }

  Map<Chapter, List<EpisodeLink>> search(String query) {
    final index = context.read<EpisodeIndexProvider>().index;
    if (query.isEmpty) return {};
    if (index == null) return {};
    final result = <Chapter, List<EpisodeLink>>{};

    query = query.katakanaized!.replaceAll(RegExp('[・、]'), '');

    for (final chapter in [...index.trilogy, ...index.aom]) {
      for (EpisodeLink episodeLink in chapter.episodeLinks) {
        if (episodeLink.title
            .replaceAll(RegExp('[・、]'), '')
            .katakanaized!
            .contains(query)) {
          if (!result.containsKey(chapter)) {
            result[chapter] = [];
          }
          result[chapter]!.add(episodeLink);
        }
      }
    }
    return result;
  }

  AppBar get appBar {
    return AppBar(
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 40, bottom: 7, right: 10),
          title: Container(
            height: 40,
            width: double.maxFinite,
            decoration: BoxDecoration(
                color:
                    context.colorTheme.background.blend(Color(0xFF7F7F7F), 0.3),
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: TextFormField(
                style: TextStyle(
                  color:
                      context.colorTheme.primary.blend(Color(0xFF7F7F7F), 0.3),
                ),
                controller: _searchTextController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    fillColor: context.colorTheme.background
                        .blend(Color(0xFF7F7F7F), 0.3),
                    hintText: "タイトルで検索",
                    hintStyle: TextStyle(
                      color: context.colorTheme.primary
                          .blend(Color(0xFF7F7F7F), 0.3),
                    ),
                    suffixIcon: GestureDetector(
                        onTap: () {
                          _searchTextController.clear();
                        },
                        child: Icon(Icons.clear,
                            color: context.colorTheme.primary))),
              ),
            ),
          )),
      shape: Border(
          bottom: BorderSide(
              color:
                  context.colorTheme.background.blend(Color(0xFF7F7F7F), 0.3),
              width: 1)),
      leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: context.colorTheme.primary.blend(Color(0xFF7F7F7F), 0.3)),
          onPressed: () => Navigator.pop(context)),
    );
  }

  void open(EpisodeLink link) async {
    if (!await NoteGateway.isCached(link.noteId)) {
      final completer = Completer<void>();
      fetchNoteBody(link.noteId).then((_) => completer.complete());
      if (!mounted) return;
      if (!await createLoadingIndicatorOnSetting(context, completer)) return;
    }
    if (!mounted) return;
    GoRouter.of(context).pushNamed(
        Routes.toName(Routes.chaptersEpisodesReadRoute),
        pathParameters: {
          'chapterId': context
              .read<EpisodeIndexProvider>()
              .getChapterIdbyEpisodeNoteId(link.noteId)!
              .toString(),
          'episodeId': link.noteId
        });
  }

  bool get hasEmojiEpisode {
    for (final links in _searchResultMap.values) {
      for (final link in links) {
        if (link.emoji != null) return true;
      }
    }
    return false;
  }

  double readProgress(EpisodeLink link) {
    final status = episodeStatus[link.noteId];
    if (status == null) return 0;
    return status.readProgress;
  }

  Future<void> updateEpisodeStatus() async {
    final result = await ReadStateGateway.getStatus(_searchResultMap.values
        .toList()
        .fold(
            [],
            (previousValue, element) =>
                previousValue..addAll(element.map((e) => e.noteId))));
    setState(() {
      episodeStatus = result;
    });
  }

  Widget historyListViewItem(int index) {
    final item = _histories[index];

    return Dismissible(
      key: ObjectKey(item),
      background: Container(
        padding: const EdgeInsets.only(
          right: 10,
        ),
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          EpisodeSearchHistoryGateway.remove(item.value);
          _histories.remove(item);
        });
      },
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: context.colorTheme.primary,
        ),
        title: Text(
          item.value,
          style: TextStyle(color: context.colorTheme.primary),
        ),
        onTap: () {
          setState(() {
            _searchTextController.text = item.value;
            _searchTextController.selection =
                TextSelection.collapsed(offset: item.value.length);
          });
        },
        trailing: IconButton(
          icon: const Icon(Icons.north_west),
          color: context.colorTheme.primary,
          onPressed: () {
            _searchTextController.text = item.value; // history and space
            _searchTextController.selection =
                TextSelection.collapsed(offset: item.value.length);
          },
        ),
      ),
    );
  }

  Widget searchResultListViewItem(int index) {
    final chapter = _searchResultMap.keys.toList()[index];
    final item = _searchResultMap[chapter]!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: context.colorTheme.secondary.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Container(
                  width: context.screenWidth,
                  // underline
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: context.colorTheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Text(chapter.title,
                        style: GoogleFonts.reggaeOne(
                          fontSize: context.textTheme.headlineSmall?.fontSize,
                          color: context.textTheme.headlineSmall?.color,
                        )),
                  ),
                ),
              ),
              for (var link in item)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    width: context.screenWidth,
                    color: context.colorTheme.background,
                    child: Column(
                      children: [
                        FilledButton(
                          style: ButtonStyle(
                            padding: MaterialStatePropertyAll(EdgeInsets.zero),
                            backgroundColor: MaterialStateProperty.all(
                                context.colorTheme.background),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1))),
                          ),
                          onPressed: () {
                            EpisodeSearchHistoryGateway.addOrTouch(
                                _searchTextController.value.text);
                            Future.delayed(Duration(milliseconds: 100), () {
                              EpisodeSearchHistoryGateway.all.then((value) {
                                setState(() {
                                  _histories = value;
                                });
                              });
                            });
                            open(link);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 8,
                                right: 8,
                                bottom: 8,
                                left: (hasEmojiEpisode ? 0 : 16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                if (hasEmojiEpisode)
                                  SizedBox(
                                    width: context.textTheme.headlineMedium!
                                            .fontSize! *
                                        2,
                                    child: Center(
                                      child: Text(link.emoji ?? '',
                                          style:
                                              context.textTheme.headlineMedium),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(link.title,
                                      style: context.textTheme.bodyLarge!
                                          .copyWith(
                                              fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(children: [
                          Expanded(
                            flex: (readProgress(link) * 100).toInt(),
                            child: Container(height: 2, color: Common.accent),
                          ),
                          Expanded(
                              flex: 100 - (readProgress(link) * 100).toInt(),
                              child: Container(
                                  height: 2,
                                  color: context.colorTheme.background
                                      .blend(context.colorTheme.primary, 0.1)))
                        ]),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.zero,
            itemCount: _searchTextController.value.text == ""
                ? _histories.length
                : _searchResultMap.length,
            itemBuilder: (context, index) {
              return _searchTextController.value.text == ""
                  ? historyListViewItem(index)
                  : searchResultListViewItem(index);
            },
          )),
    );
  }
}
