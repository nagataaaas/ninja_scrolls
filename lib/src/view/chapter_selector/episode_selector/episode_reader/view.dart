import 'dart:async';
import 'dart:developer';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:ninja_scrolls/src/providers/theme_provider.dart';
import 'package:ninja_scrolls/src/providers/wiki_index_provider.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/episode_selector/view.dart';
import 'package:ninja_scrolls/src/view/chapter_selector/read_history/view.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/create_loading_indicator_on_setting.dart';
import 'package:provider/provider.dart';
import 'package:ringo/ringo.dart';
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
  Map<String, GlobalKey> keys = {};
  int centerItemIndex = 0;
  final GlobalKey listViewKey = GlobalKey();
  List<GlobalKey> globalKeys = [];
  late final ScrollController scrollController = ScrollController(
    onAttach: (_) async {
      restoreProgress();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) saveCurrentProgress();
    },
  )..addListener(() async {
      await cacheStrategy.fetch(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        final next = getCenterItemIndex();
        if (next == -1 || next == centerItemIndex || !mounted) return;
        setState(() {
          centerItemIndex = next;
        });
      });
    });
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
        return i;
      }
    }

    return -1;
  }

  void saveCurrentProgress() {
    if (!scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) return;

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
    });
  }

  Html buildHtml(String html) {
    return Html(
      data: html,
      style: {
        'a[href^="wiki:"]': Style(
          color: context.textTheme.bodyMedium?.color,
          textDecoration: TextDecoration.underline,
          textDecorationColor:
              context.colorTheme.surface.blend(context.colorTheme.primary, 0.5),
          textDecorationThickness: 3,
        )
      },
      onLinkTap: ((url, _, __) {
        if (url == null) return;
        if (url.startsWith('wiki:')) {
          final page = WikiPage.fromJson(Uri.decodeComponent(url.substring(5)));
          openWikiPage(page);
          return;
        }
        final noteId = RegExp(r'n[0-9a-z]+', caseSensitive: false)
            .matchAsPrefix(url.split('/').last)!
            .group(0);
        if (noteId == null) return;
        final chapterId = context
            .read<EpisodeIndexProvider>()
            .getChapterIdbyEpisodeNoteId(noteId);
        if (chapterId == null) return;
        GoRouter.of(context).goNamed(
          Routes.toName(Routes.chaptersEpisodesReadRoute),
          pathParameters: {
            'chapterId': chapterId.toString(),
            'episodeId': noteId
          },
        );
      }),
    );
  }

  Widget bodyAtIndex(int index, GlobalKey key) {
    final element = content[index];
    final isCenter =
        (element.attributes['style']?.contains('text-align: center') ??
                false) ||
            element.innerHtml.contains('text-align: center');
    keys[element.attributes['name'] ?? element.innerHtml] = key;
    final isShowingCenter = key == globalKeys[centerItemIndex];

    final tags =
        RegExp(r'<([a-z]+)( .+?)?>').allMatches(element.outerHtml).map((e) {
      return e.group(1)!;
    }).toSet();
    tags.remove('figure');

    late Widget base;
    late final String body = htmlUnescape.convert(element.innerHtml
        .replaceAll('<br>', '\n')
        .replaceAll(RegExp(r'</?([a-z]+)( .+?)?>'), ''));

    if (tags.difference(const {'h2'}).isEmpty) {
      base = Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.textTheme.bodyMedium!.lineHeightPixel!),
        child: Text(
          textAlign: isCenter ? TextAlign.center : TextAlign.start,
          body,
          style: GoogleFonts.reggaeOne(
            fontSize: context.textTheme.headlineMedium?.fontSize,
            color: context.textTheme.headlineMedium?.color,
          ),
        ),
      );
    } else if ((tags.difference(const {'p', 'br'})).isEmpty) {
      Map<String, WikiPage> wikiPageFilters = {};
      if (isShowingCenter) {
        wikiPageFilters = filterWikiPages(body);
      }
      if (isShowingCenter && wikiPageFilters.isNotEmpty) {
        final queries = wikiPageFilters.keys
            .sorted((left, right) => right.length.compareTo(left.length));
        final queryRegex = RegExp("(${queries.join('|')})");

        int currentIndex = 0;
        final List<TextSpan> spans = [];
        for (final match in queryRegex.allMatches(body)) {
          if (match.start < currentIndex) continue;
          if (match.start != currentIndex) {
            spans.add(TextSpan(
                text: body.substring(currentIndex, match.start),
                style: context.textTheme.bodyMedium));
          }
          final query = match.group(0)!;
          final page = wikiPageFilters[query]!;

          spans.add(TextSpan(
              text: query,
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: context.colorTheme.surface
                    .blend(context.colorTheme.primary, 0.5),
                decorationThickness: 3,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  openWikiPage(page);
                }));

          currentIndex = match.end;
        }

        if (currentIndex < body.length) {
          spans.add(TextSpan(
              text: body.substring(currentIndex),
              style: context.textTheme.bodyMedium));
        }

        base = RichText(
            textAlign: isCenter ? TextAlign.center : TextAlign.start,
            textScaler: MediaQuery.of(context).textScaler,
            text:
                TextSpan(children: spans, style: context.textTheme.bodyMedium));
      } else {
        base = Text(
            textAlign: isCenter ? TextAlign.center : TextAlign.start, body);
      }
      base = Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.textTheme.bodyMedium!.lineHeightPixel! * 0.8),
        child: base,
      );
    } else if (tags.intersection(const {'blockquote'}).isNotEmpty) {
      base = Container(
        color:
            context.colorTheme.surface.blend(context.colorTheme.primary, 0.1),
        padding: EdgeInsets.all(
            context.textTheme.bodyMedium!.lineHeightPixel! * 0.8),
        child: Center(
          child: Text(
            textAlign: isCenter ? TextAlign.center : TextAlign.start,
            body,
            style: GoogleFonts.reggaeOne(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              color: context.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      );
    } else if (tags.intersection(const {'img'}).isNotEmpty) {
      final img = element.querySelector('img')!;
      final url = img.attributes['src']!;
      final caption = element.querySelector('figcaption')?.innerHtml;

      if (caption == null) {
        base = Padding(
          padding: EdgeInsets.symmetric(
              vertical: context.textTheme.bodyMedium.lineHeightPixel!),
          child: tryCacheImage(url),
        );
      } else {
        base = Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: context.textTheme.bodyMedium.lineHeightPixel!),
              child: tryCacheImage(url),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: context.textTheme.bodyMedium.lineHeightPixel!),
              child: buildHtml(caption),
            ),
          ],
        );
      }
    } else {
      final Map<String, WikiPage> wikiPageFilters =
          isShowingCenter ? filterWikiPages(body) : {};

      final queries = wikiPageFilters.keys
          .sorted((left, right) => right.length.compareTo(left.length));
      final queryRegex = RegExp("(${queries.join('|')})");
      final html = wikiPageFilters.isNotEmpty
          ? element.outerHtml.replaceAllMapped(queryRegex, (match) {
              final query = match.group(0)!;
              final page = wikiPageFilters[query];
              if (page == null) return query;
              return '<a href="wiki:${Uri.encodeComponent(page.toJson())}">$query</a>';
            })
          : element.outerHtml;
      base = buildHtml(html);
    }
    if (isCenter && base is! Html) {
      return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Expanded(child: base)]);
    }
    return base;
  }

  void openWikiPage(WikiPage page) async {
    context.read<WikiIndexProvider>().updateLastAccessedAt(page.title);

    GoRouter.of(context).goNamed(
      Routes.toName(Routes.searchWikiReadRoute),
      queryParameters: {'wikiTitle': page.title, 'wikiEndpoint': page.endpoint},
    );
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

  Map<String, WikiPage> filterWikiPages(String text,
      {double matchRate = 0.65}) {
    if (text.length > 300) return {};

    final sentences = text.split(RegExp(r'[！「」、。？!?\n]')).map((e) => e.trim());

    final Map<String, WikiPage> methodResult = {};

    for (final sentence in sentences) {
      if (sentence.isEmpty) continue;

      final tokenized = ringo?.tokenize(sentence);
      if (tokenized == null || tokenized.isEmpty) continue;

      final wikiIndexProvider = context.read<WikiIndexProvider>();

      int startIndex = 0;
      while (startIndex < tokenized.length) {
        WordSearchResult? result;
        int? currentMatchEndIndex;
        String? token;
        String? sanitizedToken;
        for (int endIndex = startIndex + 1;
            endIndex <= tokenized.length;
            endIndex++) {
          final currentToken = tokenized.sublist(startIndex, endIndex).join();
          final sanitizedCurrentToken =
              WikiNetworkGateway.sanitizeForSearch(currentToken);
          if (sanitizedCurrentToken.isEmpty) break;
          if (sanitizedCurrentToken.length < 3) continue;
          if (sanitizedCurrentToken == sanitizedToken) continue;

          if (sanitizedCurrentToken.length > 40) break;

          final currentResult = wikiIndexProvider.findPages(currentToken);
          if (currentResult.isEmpty) break;
          final preferredResult = currentResult.last;

          if (result == null || result.score <= preferredResult.score) {
            result = preferredResult;
            token = currentToken;
            sanitizedToken = sanitizedCurrentToken;
            currentMatchEndIndex = endIndex;
            continue;
          } else if ((preferredResult.score - result.score) < 0.2) {
            continue;
          } else {
            break;
          }
        }
        if (result != null && token != null && result.matchRate >= matchRate) {
          methodResult[token] = result.page;
        }
        if (currentMatchEndIndex != null) {
          startIndex = currentMatchEndIndex;
        } else {
          startIndex++;
        }
      }
    }
    return methodResult;
  }

  Widget widgetAtIndex(int index, BoxConstraints bodyConstraints) {
    if (globalKeys.length <= index) {
      globalKeys.add(GlobalKey(debugLabel: index.toString()));
    }
    final key = globalKeys[index];

    if (note?.eyecatchUrl != null) {
      if (--index < 0) {
        return ConstrainedBox(
          key: key,
          constraints: BoxConstraints(
              minHeight:
                  bodyConstraints.maxHeight - context.screenHeight * 0.55),
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
              )),
        );
      }
    }
    if (document != null) {
      if (index < content.length) {
        return SelectionArea(
          key: key,
          onSelectionChanged: (value) {
            log(value?.plainText ?? '');
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal:
                    context.textTheme.bodyLarge!.lineHeightPixel! * 1.5),
            child: bodyAtIndex(index, key),
          ),
        );
      }
      index -= content.length;
    }
    if ((note?.remainedCharNum ?? 0) != 0) {
      if (--index < 0) {
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.textTheme.bodyLarge!.lineHeightPixel! * 1.5),
          child: Text(
            '残り${note?.remainedCharNum}文字のエピソードを読むには、有料メンバーシップへの加入が必要です',
            style: context.textTheme.headlineSmall,
          ),
        );
      }
    }
    if (--index < 0) {
      return ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: bodyConstraints.maxHeight - context.screenHeight * 0.55),
        child: Padding(
          key: key,
          padding: EdgeInsets.symmetric(
              horizontal: context.textTheme.bodyLarge!.lineHeightPixel! * 1.5),
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
          Scrollbar(
            controller: scrollController,
            interactive: true,
            child: ListView.builder(
                key: listViewKey,
                controller: scrollController,
                itemCount: widgetCount,
                itemBuilder: (context, index) {
                  return widgetAtIndex(
                      index, BoxConstraints(maxHeight: context.screenHeight));
                }),
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
