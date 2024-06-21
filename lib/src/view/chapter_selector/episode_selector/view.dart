import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
import 'package:ninja_scrolls/src/view/components/episode_selector/build_chapter.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/create_loading_indicator_on_setting.dart';
import 'package:provider/provider.dart';

class EpisodeSelectorViewArgument {
  final int chapterId;

  EpisodeSelectorViewArgument(this.chapterId);
}

class EpisodeSelectorView extends StatefulWidget {
  final EpisodeSelectorViewArgument argument;
  const EpisodeSelectorView({super.key, required this.argument});

  @override
  State<EpisodeSelectorView> createState() => EpisodeSelectorViewState();
}

class EpisodeSelectorViewState extends State<EpisodeSelectorView> {
  late Chapter? chapter = context
      .watch<EpisodeIndexProvider>()
      .getChapterById(widget.argument.chapterId);
  Key? lastChapterObjectKey;
  late List<EpisodeLink>? episodeLinks = chapter?.episodeLinks;
  Map<String, ReadStatus>? episodeStatus;
  late final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await updateEpisodeStatusIfNeeded();
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> updateEpisodeStatusIfNeeded() async {
    if (chapter == null) return;
    final newKey = ObjectKey(chapter);
    if (lastChapterObjectKey == newKey) return;
    lastChapterObjectKey = newKey;
    await updateEpisodeStatus();
  }

  Future<void> updateEpisodeStatus() async {
    final result = await ReadStateGateway.getStatus(
        episodeLinks!.map((e) => e.noteId).toList());
    setState(() {
      episodeStatus = result;
    });
  }

  Html buildHTML(String html, [Map<String, Style>? style]) => Html(
        data: html,
        style: style ??
            {
              "body": Style(
                fontFamily: "Noto Sans JP",
                fontSize: FontSize(context.textTheme.bodyMedium!.fontSize!),
                color: context.colorTheme.primary,
              ),
            },
      );

  int get totalEpisodeCount {
    if (chapter == null) return 0;
    var count = 0;
    for (var chapterChild in chapter!.chapterChildren) {
      if (chapterChild.isEpisodeLinkGroup) {
        count += chapterChild.episodeLinkGroup!.links.length;
      }
    }
    return count;
  }

  bool get hasEmojiEpisode {
    if (episodeLinks == null) return false;
    for (var episodeLink in episodeLinks!) {
      if (episodeLink.emoji != null) return true;
    }
    return false;
  }

  double readProgress(EpisodeLink link) {
    if (chapter == null) return 0;
    if (episodeStatus == null) return 0;
    final status = episodeStatus![link.noteId];
    if (status == null) return 0;
    return status.readProgress;
  }

  EpisodeLink? get nextEpisode {
    if (episodeLinks == null) return null;
    if (episodeStatus == null) return null;

    for (var episodeLink in episodeLinks!) {
      final status = episodeStatus![episodeLink.noteId];
      if (status == null) continue;
      if (status.state != ReadState.read) return episodeLink;
    }
    return null;
  }

  Widget buildGuide(String guide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.colorTheme.primary.withOpacity(0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text('ガイドな', style: GoogleFonts.reggaeOne(fontSize: 20)),
              buildHTML(guide, {
                "body": Style(
                  fontFamily: "Noto Sans JP",
                  fontSize: FontSize(context.textTheme.bodyLarge!.fontSize!),
                  color: context.textTheme.bodyLarge?.color,
                ),
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEpisodeGroup(EpisodeLinkGroup group) {
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
              if (group.groupName != null)
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
                      child: Text(group.groupName!,
                          style: GoogleFonts.reggaeOne(
                            fontSize: context.textTheme.headlineSmall?.fontSize,
                            color: context.textTheme.headlineSmall?.color,
                          )),
                    ),
                  ),
                ),
              for (var link in group.links)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    width: context.screenWidth,
                    color: context.colorTheme.surface,
                    child: Column(
                      children: [
                        FilledButton(
                          style: ButtonStyle(
                            padding: MaterialStatePropertyAll(EdgeInsets.zero),
                            backgroundColor: MaterialStateProperty.all(
                                context.colorTheme.surface),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1))),
                          ),
                          onPressed: () => open(link),
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
                                      child: Text(
                                        link.emoji ?? '',
                                        style: context.textTheme.headlineMedium,
                                      ),
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
                                  color: context.colorTheme.surface
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

  void open(EpisodeLink link) async {
    if (!await NoteGateway.isCached(link.noteId)) {
      final completer = Completer<void>();
      fetchNoteBody(link.noteId).then((_) => completer.complete());
      if (!mounted) return;
      if (!await createLoadingIndicatorOnSetting(context, completer)) return;
    }
    if (!mounted) return;
    GoRouter.of(context).goNamed(
        Routes.toName(Routes.chaptersEpisodesReadRoute),
        pathParameters: {
          'chapterId': widget.argument.chapterId.toString(),
          'episodeId': link.noteId
        });
  }

  @override
  Widget build(BuildContext context) {
    updateEpisodeStatusIfNeeded();

    return Scaffold(
      backgroundColor: context.colorTheme.surface,
      body: SafeArea(
        child: chapter == null
            ? Center(
                child: CircularProgressIndicator.adaptive(),
              )
            : RefreshIndicator.adaptive(
                onRefresh: () async {
                  await updateEpisodeStatus();
                },
                child: Scrollbar(
                  controller: scrollController,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildChapter(context, chapter!, false),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Text(
                            chapter!.title,
                            style: context.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Row(children: [
                            Icon(
                              Icons.menu_book,
                              size:
                                  context.textTheme.bodyMedium!.fontSize! * 1.5,
                              color: context.colorTheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text("$totalEpisodeCount話",
                                style: context.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        buildHTML(chapter!.description),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: FilledButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    context.colorTheme.primary),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))),
                              ),
                              onPressed: () => open(chapter!.firstEpisodeLink!),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Icon(Icons.chrome_reader_mode),
                                    SizedBox(width: 8),
                                    Text("初めから読む",
                                        style: context.textTheme.bodyLarge!
                                            .copyWith(
                                          color: context.colorTheme.onPrimary,
                                        ))
                                  ],
                                ),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: FilledButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    context.colorTheme.surface.blend(
                                        context.colorTheme.primary, 0.1)),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))),
                              ),
                              onPressed: () {
                                final link = nextEpisode;
                                if (link != null) open(link);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Icon(Icons.chrome_reader_mode,
                                        color: context.colorTheme.primary),
                                    SizedBox(width: 8),
                                    Text("続きを読む",
                                        style: context.textTheme.bodyLarge!
                                            .copyWith(
                                          color: context.colorTheme.primary,
                                        ))
                                  ],
                                ),
                              )),
                        ),
                        for (var chapterChild in chapter!.chapterChildren)
                          chapterChild.isGuide
                              ? buildGuide(chapterChild.guide!)
                              : buildEpisodeGroup(
                                  chapterChild.episodeLinkGroup!),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
