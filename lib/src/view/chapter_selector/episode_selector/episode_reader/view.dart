import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/gateway/sqlite.dart';
import 'package:ninja_scrolls/src/providers/index_provider.dart';
import 'package:ninja_scrolls/src/providers/reader_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/view.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/throwing_shuriken.dart';
import 'package:ninja_scrolls/src/view/scaffold/appbar_title_bloc.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EpisodeReaderViewArgument {
  final int chapterId;
  final String episodeId;

  EpisodeReaderViewArgument({
    required this.chapterId,
    required this.episodeId,
  });
}

class EpisodeReaderView extends StatefulWidget {
  final EpisodeReaderViewArgument argument;
  const EpisodeReaderView({super.key, required this.argument});

  @override
  State<EpisodeReaderView> createState() => EpisodeReaderViewState();
}

class EpisodeReaderViewState extends State<EpisodeReaderView> {
  Note? note;
  dom.Document? document;
  List<dom.Element>? _content;
  bool hasNFiles = false;
  List<Widget>? _body;
  Map<String, GlobalKey> keys = {};
  bool scrollControllerAttached = false;
  late final ScrollController scrollController = ScrollController(
    onAttach: (_) async {
      scrollControllerAttached = true;
      restoreProgress();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) saveCurrentProgress();
    },
  );
  late final episode = context
      .read<IndexProvider>()
      .getEpisodeLinkFromNoteId(widget.argument.episodeId)!;
  late EpisodeLink? previousEpisode =
      context.watch<IndexProvider>().previous(episode);
  late EpisodeLink? nextEpisode = context.watch<IndexProvider>().next(episode);

  @override
  void initState() {
    super.initState();
    // after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appBloc.updateTitle(episode.title);

      fetchNoteBody(episode.noteId).then((value) {
        if (!mounted) return;
        setState(() {
          note = value;
          context.read<ReaderProvider>().endDrawer = buildEndDrawer();
          document = html_parser.parse(value.html);
        });
      });
    });
  }

  @override
  void dispose() {
    EpisodeSelectorViewState state =
        episodeSelectorKey.currentState as EpisodeSelectorViewState;
    state.updateEpisodeStatus();
    if (shellScaffoldKey.currentState?.isEndDrawerOpen == true) {
      shellScaffoldKey.currentState?.closeEndDrawer();
    }
    super.dispose();
    scrollController.dispose();
  }

  void saveCurrentProgress() {
    final maxHeight = scrollController.position.maxScrollExtent;
    final currentHeight = scrollController.position.pixels;
    double progress = currentHeight / maxHeight;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    final readState = progress > 0.95 ? ReadState.read : ReadState.reading;
    ReadStateGateway.updateStatus(episode.noteId, readState, progress);

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      saveCurrentProgress();
    });
  }

  void restoreProgress() {
    if (!scrollControllerAttached) return;
    // check scrollController is attached
    if (scrollController.position.maxScrollExtent == 0.0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        restoreProgress();
      });
      return;
    }

    final noteId = episode.noteId;
    ReadStateGateway.getStatus([noteId]).then((value) async {
      if (!mounted) return;
      if (!value.containsKey(noteId)) return;
      while (scrollController.position.maxScrollExtent == 0.0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      scrollController.position.animateTo(
          scrollController.position.maxScrollExtent *
              value[noteId]!.readProgress,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    });
  }

  Widget tryCacheImage(String url) {
    if (url.isEmpty) return Container();
    if (url.endsWith('.svg')) {
      return SvgPicture.network(url);
    }
    return CachedNetworkImage(imageUrl: url);
  }

  Widget buildEndDrawer() {
    if (!mounted) return Container();
    return Drawer(
      shape: RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.only(
            top: 8.0, right: 8.0, bottom: 16.0, left: 8.0),
        child: SafeArea(
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Scrollbar(
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('目次',
                                style: GoogleFonts.reggaeOne(
                                    fontSize: context
                                        .textTheme.headlineMedium!.fontSize)),
                            IconButton(
                                onPressed: () async {
                                  context.read<ReaderProvider>().endDrawer =
                                      buildEndDrawer();
                                },
                                icon: Icon(Icons.refresh))
                          ],
                        ),
                      ),
                      ...(note!.availableIndexItems.map((e) {
                        return ListTile(
                          title: Text(e.title),
                          onTap: () {
                            Scrollable.ensureVisible(
                              keys[e.id]!.currentContext!,
                              duration: const Duration(milliseconds: 500),
                            );
                          },
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),
            ),
            if (note?.bookPurchaseLink != null)
              AspectRatio(
                aspectRatio: 9 / 16 * 2,
                child: GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(note!.bookPurchaseLink!.url);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note!.bookPurchaseLink!.imageUrl != null) ...[
                          Expanded(
                              child: tryCacheImage(
                                  note!.bookPurchaseLink!.imageUrl!)),
                          SizedBox(width: 12),
                        ],
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              note!.bookPurchaseLink!.title,
                              style: context.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(note!.bookPurchaseLink!.price),
                            Text('外部ページで購入')
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(child: previousButton),
                SizedBox(
                  width: 9,
                ),
                Expanded(child: nextButton),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> get body {
    _body ??= content.map((element) {
      final key = GlobalKey();
      final isCenter =
          element.attributes['style']?.contains('text-align: center') ?? false;
      keys[element.attributes['name'] ?? element.innerHtml] = key;

      final tags =
          RegExp(r'<([a-z]+)( .+?)?>').allMatches(element.outerHtml).map((e) {
        return e.group(1)!;
      }).toSet();

      late final Widget base;

      if (tags.difference(const {'h2'}).isEmpty) {
        base = Padding(
          padding: EdgeInsets.symmetric(
              vertical: context.textTheme.bodyMedium!.lineHeightPixel!),
          child: Text(
              textAlign: isCenter ? TextAlign.center : TextAlign.start,
              key: key,
              element.innerHtml
                  .replaceAll('<br>', '\n')
                  .replaceAll(RegExp(r'<([a-z]+)( .+?)?>'), ''),
              style: GoogleFonts.reggaeOne(
                fontSize: context.textTheme.headlineMedium!.fontSize,
              )),
        );
      } else if ((tags.difference(const {'p', 'br'})).isEmpty) {
        base = Padding(
          padding: EdgeInsets.symmetric(
              vertical: context.textTheme.bodyMedium!.lineHeightPixel! * 0.8),
          child: Text(
              textAlign: isCenter ? TextAlign.center : TextAlign.start,
              key: key,
              element.innerHtml
                  .replaceAll('<br>', '\n')
                  .replaceAll(RegExp(r'<([a-z]+)( .+?)?>'), '')),
        );
      } else {
        base = Html(key: key, data: element.innerHtml);
      }
      if (isCenter && base is! Html) {
        return Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Expanded(child: base)]);
      }
      return base;
    }).toList();
    return _body!;
  }

  List<dom.Element> get content {
    if (document == null) return [];

    _content ??= document!.body!.children.where((element) {
      if (hasNFiles && !note!.canReadAll) return false;

      final innerHtml = element.innerHtml;
      if (innerHtml.contains("連載時のログをそのままアーカイブ") ||
          innerHtml.contains("収録された書籍限定エピソード")) {
        // description
        return false;
      }
      if (innerHtml.contains("nd9ea95a7fd60") ||
          innerHtml.contains("全話リストへ戻る")) {
        // link
        return false;
      }
      if (RegExp(r'n-?files?', caseSensitive: false).hasMatch(innerHtml)) {
        hasNFiles = true;
        return note!.canReadAll;
      }
      if (innerHtml.contains(RegExp(
          r'href="https?://(www.)?amazon(.co)?(.jp)?/.+"',
          caseSensitive: false))) {
        // amazon link
        return false;
      }
      if (innerHtml.contains(RegExp(r'href="https?://(www.)?mimicle(.com)?/.+"',
          caseSensitive: false))) {
        // mimicle link (audio)
        return false;
      }

      if (element.text.trim().isEmpty) return false;

      return true;
    }).toList();
    return _content!;
  }

  Widget get previousButton {
    return Column(
      children: [
        Text('PREVIOUS'),
        FilledButton(
          onPressed: previousEpisode == null
              ? null
              : () async {
                  if (previousEpisode == null) return;
                  if (!await NoteGateway.isCached(previousEpisode!.noteId)) {
                    final completer = Completer<void>();
                    fetchNoteBody(previousEpisode!.noteId)
                        .then((_) => completer.complete());
                    if (!await createThrowingShuriken(completer)) return;
                  }
                  if (!mounted) return;
                  GoRouter.of(context).pushReplacementNamed(
                    Routes.toName(Routes.chaptersEpisodesReadRoute),
                    pathParameters: {
                      'chapterId': widget.argument.chapterId.toString(),
                      'episodeId': previousEpisode!.noteId
                    },
                  );
                },
          child: SizedBox(
              height: context.textTheme.bodyMedium.lineHeightPixel! * 3,
              child:
                  Center(child: Text(previousEpisode?.title ?? '見つかりませんでした'))),
        ),
      ],
    );
  }

  Widget get nextButton {
    return Column(
      children: [
        Text('NEXT'),
        FilledButton(
          onPressed: () async {
            if (nextEpisode == null) return;
            if (!await NoteGateway.isCached(nextEpisode!.noteId)) {
              final completer = Completer<void>();
              fetchNoteBody(nextEpisode!.noteId)
                  .then((_) => completer.complete());
              if (!await createThrowingShuriken(completer)) return;
            }
            if (!mounted) return;
            GoRouter.of(context).pushReplacementNamed(
              Routes.toName(Routes.chaptersEpisodesReadRoute),
              pathParameters: {
                'chapterId': widget.argument.chapterId.toString(),
                'episodeId': nextEpisode!.noteId
              },
            );
          },
          child: SizedBox(
              height: context.textTheme.bodyMedium.lineHeightPixel! * 3,
              child: Center(child: Text(nextEpisode?.title ?? '見つかりませんでした'))),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Scrollbar(
          child: Column(
            children: [
              if (note?.eyecatchUrl != null)
                CachedNetworkImage(imageUrl: note!.eyecatchUrl!),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.textTheme.bodyLarge!.lineHeightPixel!),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: document == null ? 0 : body.length,
                  itemBuilder: (context, index) => body[index],
                ),
              ),
              if (document != null && body.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Text(
                      "このエピソードの閲覧には、有料メンバーシップへの加入が必要です",
                      style: context.textTheme.headlineSmall,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.textTheme.bodyLarge!.lineHeightPixel!),
                child: Row(
                  children: [
                    Expanded(child: previousButton),
                    SizedBox(width: 10),
                    Expanded(child: nextButton),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
