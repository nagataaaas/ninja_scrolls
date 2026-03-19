import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:html_unescape/html_unescape.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';
import 'package:ninja_scrolls/src/providers/episode_index_provider.dart';
import 'package:ninja_scrolls/src/providers/wiki_index_provider.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:provider/provider.dart';
import 'package:ringo/ringo.dart';
import 'package:widget_zoom/widget_zoom.dart';

final htmlUnescape = HtmlUnescape();

class HtmlWidget extends StatefulWidget {
  final int selfIndex;
  final Ringo? ringo;
  final dom.Element element;
  final Stream<int> middleItemIndexStream;
  const HtmlWidget(
      {super.key,
      required this.ringo,
      required this.selfIndex,
      required this.element,
      required this.middleItemIndexStream});

  @override
  State<HtmlWidget> createState() => _HtmlWidgetState();
}

class _HtmlWidgetState extends State<HtmlWidget> {
  bool isMiddle = false;
  bool isCenter = false;

  @override
  void initState() {
    super.initState();
    isCenter =
        (widget.element.attributes['style']?.contains('text-align: center') ??
                false) ||
            widget.element.innerHtml.contains('text-align: center');
    widget.middleItemIndexStream.listen((index) {
      if (!mounted) return;
      if (isMiddle == (index == widget.selfIndex)) return;
      setState(() {
        isMiddle = !isMiddle;
      });
    });
  }

  @override
  void dispose() {
    widget.middleItemIndexStream.drain();
    super.dispose();
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

  Map<String, WikiPage> filterWikiPages(String text,
      {double matchRate = 0.65}) {
    if (text.length > 300) return {};

    final sentences = text.split(RegExp(r'[！「」、。？!?\n]')).map((e) => e.trim());

    final Map<String, WikiPage> methodResult = {};

    for (final sentence in sentences) {
      if (sentence.isEmpty) continue;

      final tokenized = widget.ringo?.tokenize(sentence);
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

  void openWikiPage(WikiPage page) async {
    context.read<WikiIndexProvider>().updateLastAccessedAt(page.title);

    GoRouter.of(context).goNamed(
      Routes.toName(Routes.searchWikiReadRoute),
      queryParameters: {'wikiTitle': page.title, 'wikiEndpoint': page.endpoint},
    );
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

  Widget buildHeadline(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: context.textTheme.bodyMedium!.lineHeightPixel!),
      child: Text(
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        text,
        style: GoogleFonts.reggaeOne(
          fontSize: context.textTheme.headlineMedium?.fontSize,
          color: context.textTheme.headlineMedium?.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
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
      base = buildHeadline(body);
    } else if ((tags.difference(const {'p', 'br'})).isEmpty) {
      Map<String, WikiPage> wikiPageFilters = {};
      if (isMiddle) {
        wikiPageFilters = filterWikiPages(body);
      }
      if (isMiddle && wikiPageFilters.isNotEmpty) {
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
          isMiddle ? filterWikiPages(body) : {};

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
}
