import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/create_loading_indicator_on_setting.dart';
import 'package:provider/provider.dart';

class ReadHistoryView extends StatefulWidget {
  const ReadHistoryView({super.key});

  @override
  State<ReadHistoryView> createState() => ReadHistoryViewState();
}

class ReadHistoryViewState extends State<ReadHistoryView> {
  static const maxHistory = 30;

  bool loading = true;
  List<EpisodeLink> history = [];
  Map<String, int> chapterIdByNoteId = {};
  Map<String, ReadStatus>? episodeStatus;
  late final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future load() async {
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
          loading = true;
        }));
    final notes = await NoteGateway.recentRead(maxHistory);
    if (!mounted) return;
    history = context
        .read<EpisodeIndexProvider>()
        .getEpisodeLinksByNoteIds(notes.map((e) => e.id).toList())
        .cast();
    chapterIdByNoteId = context
        .read<EpisodeIndexProvider>()
        .getChapterIdbyEpisodeNoteIds(notes.map((e) => e.id).toList());
    final result =
        await ReadStateGateway.getStatus(history.map((e) => e.noteId).toList());

    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
          episodeStatus = result;
          loading = false;
        }));
  }

  bool get hasEmojiEpisode {
    for (var episodeLink in history) {
      if (episodeLink.emoji != null) return true;
    }
    return false;
  }

  double readProgress(EpisodeLink link) {
    if (episodeStatus == null) return 0;
    final status = episodeStatus![link.noteId];
    if (status == null) return 0;
    return status.readProgress;
  }

  int get widgetCount {
    int count = 0;
    int? currentChapterId;

    for (var episodeLink in history) {
      final chapterForCurrent = chapterIdByNoteId[episodeLink.noteId];
      if (chapterForCurrent != currentChapterId) {
        currentChapterId = chapterForCurrent;
        count++;
      }
      count++;
    }

    return count;
  }

  Widget widgetForIndex(int index) {
    int? currentChapterId;

    for (var episodeLink in history) {
      final chapterForCurrent = chapterIdByNoteId[episodeLink.noteId];
      if (chapterForCurrent != currentChapterId) {
        currentChapterId = chapterForCurrent;
        if (index-- == 0) {
          return listHeader(context
              .read<EpisodeIndexProvider>()
              .getChapterById(currentChapterId!)!
              .title);
        }
      }
      if (index-- == 0) {
        return buildEpisode(episodeLink);
      }
    }
    return Container();
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
          'chapterId': chapterIdByNoteId[link.noteId].toString(),
          'episodeId': link.noteId
        });
  }

  Widget buildEpisode(EpisodeLink episodeLink) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        width: context.screenWidth,
        color: context.colorTheme.background,
        child: Column(
          children: [
            FilledButton(
              style: ButtonStyle(
                padding: MaterialStatePropertyAll(EdgeInsets.zero),
                backgroundColor:
                    MaterialStateProperty.all(context.colorTheme.background),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1))),
              ),
              onPressed: () => open(episodeLink),
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
                        width: context.textTheme.headlineMedium!.fontSize! * 2,
                        child: Center(
                          child: Text(
                            episodeLink.emoji ?? '',
                            style: context.textTheme.headlineMedium,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(episodeLink.title,
                          style: context.textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            Row(children: [
              Expanded(
                flex: (readProgress(episodeLink) * 100).toInt(),
                child: Container(height: 2, color: Common.accent),
              ),
              Expanded(
                  flex: 100 - (readProgress(episodeLink) * 100).toInt(),
                  child: Container(
                      height: 2,
                      color: context.colorTheme.background
                          .blend(context.colorTheme.primary, 0.1)))
            ]),
          ],
        ),
      ),
    );
  }

  Widget listHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Container(
        width: context.screenWidth,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: context.colorTheme.primary,
              width: 6,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(title,
              style: GoogleFonts.reggaeOne(
                fontSize: context.textTheme.headlineMedium?.fontSize,
                color: context.textTheme.headlineMedium?.color,
              )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Scrollbar(
      controller: scrollController,
      child: RefreshIndicator.adaptive(
        onRefresh: () async => load(),
        child: loading || widgetCount == 0
            ? LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: loading
                          ? CircularProgressIndicator.adaptive()
                          : Text('履歴はありません'),
                    ),
                  ),
                );
              })
            : ListView.builder(
                itemCount: widgetCount,
                itemBuilder: (BuildContext context, int index) =>
                    widgetForIndex(index),
              ),
      ),
    ));
  }
}
