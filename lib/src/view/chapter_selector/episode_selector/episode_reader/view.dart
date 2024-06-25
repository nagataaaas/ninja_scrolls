import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/navkey.dart';
import 'package:ninja_scrolls/route_observer.dart';
import 'package:ninja_scrolls/src/gateway/database/note.dart';
import 'package:ninja_scrolls/src/gateway/database/read_state.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/episode_reader/components/htmlWidget.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/read_history/view.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/create_loading_indicator_on_setting.dart';
import 'package:ninja_scrolls/src/view/components/swipe_to_pop_container.dart';
import 'package:provider/provider.dart';
import 'package:ringo/ringo.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:widget_zoom/widget_zoom.dart';

final htmlUnescape = HtmlUnescape();

Ringo? ringo;
final cacheStrategy = AsyncCache.ephemeral();

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
  Map<String, GlobalKey> keyByItemId = {};
  int middleItemIndex = 0;
  StreamController<int> middleItemIndexStreamController =
      StreamController<int>.broadcast();
  final GlobalKey listViewKey = GlobalKey();
  List<GlobalKey> globalKeys = [];
  late final ScrollController scrollController = ScrollController(
    onAttach: (_) async {
      restoreProgress();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await saveCurrentProgress();
    },
  )..addListener(() async {
      await cacheStrategy.fetch(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        final next = getCenterItemIndex();
        if (next == middleItemIndex || !mounted) return;
        setState(() {
          middleItemIndex = next;
        });
        middleItemIndexStreamController.add(middleItemIndex);
      });
    });
  late final ListObserverController listObserverController =
      ListObserverController(controller: scrollController);
  late final episode = context
      .read<EpisodeIndexProvider>()
      .getEpisodeLinkFromNoteId(widget.argument.episodeId)!;
  late EpisodeLink? previousEpisode =
      context.watch<EpisodeIndexProvider>().previous(episode);
  late EpisodeLink? nextEpisode =
      context.watch<EpisodeIndexProvider>().next(episode);

  @override
  void initState() {
    super.initState();

    if (ringo == null) {
      Ringo.init().then((rin) => ringo = rin);
    }

    // after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScaffoldProvider>().episodeTitle = episode.title;

      fetchNoteBody(episode.noteId, readNow: true).then((value) {
        if (!mounted) return;
        setState(() {
          note = value;
          context.read<ScaffoldProvider>().endDrawer = buildEndDrawer();
          document = html_parser.parse(value.html);
        });
      });
    });
  }

  @override
  void dispose() async {
    scrollController.dispose();
    super.dispose();

    if (readShellRouteObserver
        .hasOnStack(Routes.toName(Routes.chaptersEpisodesRoute))) {
      EpisodeSelectorViewState? episodeSelectorViewState =
          episodeSelectorKey.currentState as EpisodeSelectorViewState?;
      await episodeSelectorViewState?.updateEpisodeStatus();
    }

    if (readShellRouteObserver
        .hasOnStack(Routes.toName(Routes.readHistoryRoute))) {
      ReadHistoryViewState? readHistoryViewState =
          readHistoryKey.currentState as ReadHistoryViewState?;
      await readHistoryViewState?.load();
    }

    if (shellScaffoldKey.currentState?.isEndDrawerOpen == true) {
      shellScaffoldKey.currentState?.closeEndDrawer();
    }
  }

  int getCenterItemIndex() {
    final listViewBox =
        listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewBox == null) return 0;
    final listViewTop = listViewBox.localToGlobal(Offset.zero).dy;
    final listViewBottom = listViewTop + listViewBox.size.height;
    final listViewCenter = listViewTop + listViewBox.size.height / 2;

    for (var i = 0; i < globalKeys.length; i++) {
      var itemTop = 0.0;
      var itemBottom = 0.0;
      try {
        final itemBox =
            globalKeys[i].currentContext!.findRenderObject() as RenderBox?;
        itemTop = itemBox!.localToGlobal(Offset.zero).dy;
        itemBottom = itemTop + itemBox.size.height;
      } catch (e) {
        // item is not visible
      }

      if (itemTop > listViewBottom) {
        break;
      }

      if (itemTop <= listViewCenter && itemBottom >= listViewCenter) {
        return i - (note?.eyecatchUrl != null ? 1 : 0);
      }
    }

    return -1;
  }

  Future<void> saveCurrentProgress() async {
    if (!scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) return;

    final maxHeight = scrollController.position.maxScrollExtent;
    final currentHeight = scrollController.position.pixels;
    double progress = currentHeight / maxHeight;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    final readState = progress > 0.95 ? ReadState.read : ReadState.reading;
    ReadStateGateway.updateStatus(
        episode.noteId, readState, progress, middleItemIndex);

    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      await saveCurrentProgress();
    });
  }

  void restoreProgress() {
    if (!scrollController.hasClients ||
        !scrollController.position.hasContentDimensions ||
        scrollController.position.maxScrollExtent == 0.0) {
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
      final index = value[noteId]!.index - (note?.eyecatchUrl != null ? 1 : 0);
      if (index <= 1) return;
      listObserverController.animateTo(
          index: index - 1,
          duration: const Duration(milliseconds: 500),
          alignment: 1,
          curve: Curves.easeOut);
    });
  }

  Widget tryCacheImage(String url) {
    if (url.isEmpty) return Container();
    if (url.endsWith('.svg')) {
      return WidgetZoom(
          heroAnimationTag: url, zoomWidget: SvgPicture.network(url));
    }
    return WidgetZoom(
        heroAnimationTag: url, zoomWidget: CachedNetworkImage(imageUrl: url));
  }

  Widget buildEndDrawer() {
    if (!mounted) return Container();
    return Builder(builder: (context) {
      context.watch<ThemeProvider>;
      return Drawer(
        shape: RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.only(
              top: 8.0, right: 8.0, bottom: 16.0, left: 8.0),
          child: SafeArea(
            child: Column(children: [
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
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
                                        .textTheme.headlineMedium?.fontSize,
                                    color:
                                        context.textTheme.headlineMedium?.color,
                                  )),
                              IconButton(
                                  onPressed: () async {
                                    context.read<ScaffoldProvider>().endDrawer =
                                        buildEndDrawer();
                                  },
                                  icon: Icon(Icons.refresh,
                                      color: context.colorTheme.primary))
                            ],
                          ),
                        ),
                        ...(note!.availableIndexItems.map((e) {
                          return ListTile(
                            title: Text(e.title),
                            onTap: () {
                              final index = content.indexWhere((element) {
                                return element.attributes['name'] == e.id;
                              });
                              if (index == -1) return;
                              listObserverController.animateTo(
                                  index: index,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic);
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
                  aspectRatio: 9 / 8,
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
                                child: AspectRatio(
                              aspectRatio: 259 / 368,
                              child: CachedNetworkImage(
                                  imageUrl: note!.bookPurchaseLink!.imageUrl ??
                                      'https://via.placeholder.com/150'),
                            )),
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
    });
  }

  List<dom.Element> get content {
    if (document == null) return [];

    _content ??= document!.body!.children.where((element) {
      if (hasNFiles && !note!.canReadAll) return false;

      final html = element.outerHtml;
      if (html.contains("連載時のログをそのままアーカイブ") ||
          html.contains("収録された書籍限定エピソード")) {
        // description
        return false;
      }
      if (html.contains("nd9ea95a7fd60") || html.contains("全話リストへ戻る")) {
        // link
        return false;
      }
      if (RegExp(r'n-?files?', caseSensitive: false).hasMatch(html)) {
        hasNFiles = true;
        return note!.canReadAll;
      }
      if (html.contains(RegExp(r'href="https?://(www.)?amazon(.co)?(.jp)?/.+"',
          caseSensitive: false))) {
        // amazon link
        return false;
      }
      if (html.contains(RegExp(r'href="https?://(www.)?mimicle(.com)?/.+"',
          caseSensitive: false))) {
        // mimicle link (audio)
        return false;
      }

      if (!html.contains('<img') && element.text.trim().isEmpty) return false;

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
                    if (!mounted) return;
                    if (!await createLoadingIndicatorOnSetting(
                        context, completer)) return;
                  }
                  if (!mounted) return;
                  GoRouter.of(context).goNamed(
                    Routes.toName(Routes.chaptersEpisodesReadRoute),
                    pathParameters: {
                      'chapterId': context
                          .read<EpisodeIndexProvider>()
                          .getChapterIdbyEpisodeNoteId(previousEpisode!.noteId)!
                          .toString(),
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
              if (!mounted) return;
              if (!await createLoadingIndicatorOnSetting(context, completer)) {
                return;
              }
            }
            if (!mounted) return;
            GoRouter.of(context).goNamed(
              Routes.toName(Routes.chaptersEpisodesReadRoute),
              pathParameters: {
                'chapterId': context
                    .read<EpisodeIndexProvider>()
                    .getChapterIdbyEpisodeNoteId(nextEpisode!.noteId)!
                    .toString(),
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

  int get widgetCount {
    int result = 0;
    if (note?.eyecatchUrl != null) result++;
    if (document != null) result += content.length;
    if (note != null && note!.remainedCharNum != 0) result++;
    result += 2;
    return result;
  }

  Widget buildEyeCatch(Key key, BoxConstraints bodyConstraints) {
    return ConstrainedBox(
      key: key,
      constraints: BoxConstraints(
          minHeight: bodyConstraints.maxHeight - context.screenHeight * 0.55),
      child: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 1280 / 670,
          child: CachedNetworkImage(
            imageUrl: note!.eyecatchUrl!,
            placeholder: (context, url) {
              return Container(
                color: context.colorTheme.surface,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildPaidMembershipRequiredBlock(Key key) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(
          horizontal: context.textTheme.bodyLarge!.lineHeightPixel! * 1.5),
      child: Text(
        '残り${note?.remainedCharNum}文字のエピソードを読むには、有料メンバーシップへの加入が必要です',
        style: context.textTheme.headlineSmall,
      ),
    );
  }

  Widget buildNavigationButtons(Key key, BoxConstraints bodyConstraints) {
    return ConstrainedBox(
      key: key,
      constraints: BoxConstraints(
          minHeight: bodyConstraints.maxHeight - context.screenHeight * 0.55),
      child: Padding(
        key: key,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: previousButton),
            SizedBox(width: 10),
            Expanded(child: nextButton),
          ],
        ),
      ),
    );
  }

  Widget widgetAtIndex(int index, BoxConstraints bodyConstraints) {
    if (globalKeys.length <= index) {
      for (int i = globalKeys.length; i <= index; i++) {
        globalKeys
            .add(GlobalKey(debugLabel: '${Random.secure()}${i.toString()}'));
      }
    }
    final key = globalKeys[index];

    if (note?.eyecatchUrl != null) {
      if (--index < 0) {
        return buildEyeCatch(key, bodyConstraints);
      }
    }
    if (document != null) {
      if (index < content.length) {
        final element = content[index];
        keyByItemId[element.attributes['name'] ?? element.innerHtml] = key;

        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.textTheme.bodyLarge!.lineHeightPixel! * 1.5),
          child: HtmlWidget(
            key: key,
            ringo: ringo,
            element: content[index],
            selfIndex: index,
            middleItemIndexStream: middleItemIndexStreamController.stream,
          ),
        );
      }
      index -= content.length;
    }
    if ((note?.remainedCharNum ?? 0) != 0) {
      if (--index < 0) {
        return buildPaidMembershipRequiredBlock(key);
      }
    }
    if (--index < 0) {
      return buildNavigationButtons(key, bodyConstraints);
    }
    if (--index < 0) {
      return SizedBox(key: key, height: 20);
    }
    return Container(
      key: key,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.centerLeft,
        children: [
          SwipeToPopContainer(
            enabled: Platform.isIOS,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              interactive: true,
              child: ListViewObserver(
                controller: listObserverController,
                child: ListView.builder(
                    key: listViewKey,
                    controller: scrollController,
                    itemCount: widgetCount,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return widgetAtIndex(index,
                          BoxConstraints(maxHeight: context.screenHeight));
                    }),
              ),
            ),
          ),
          SizedBox(
              width: context.textTheme.bodyLarge!.lineHeightPixel! * 1.5,
              child: Icon(Icons.manage_search,
                  color: context.textTheme.bodyMedium?.color))
        ],
      ),
    );
  }
}
