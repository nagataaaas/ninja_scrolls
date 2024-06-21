import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:ninja_scrolls/src/providers/wiki_index_provider.dart';
import 'package:ninja_scrolls/src/static/colors.dart';
import 'package:ninja_scrolls/src/static/routes.dart';
import 'package:provider/provider.dart';

class SearchWikiView extends StatefulWidget {
  const SearchWikiView({super.key});

  @override
  State<SearchWikiView> createState() => _SearchWikiViewState();
}

class _SearchWikiViewState extends State<SearchWikiView> {
  late final TextEditingController _searchTextController;
  List<WikiPage> _searchResult = [];
  late final FocusNode searchTextFocusNode;
  late final ScrollController scrollController = ScrollController();

  late final readWikiIndexProvider = context.read<WikiIndexProvider>();

  @override
  void initState() {
    super.initState();
    searchTextFocusNode = FocusNode();
    _searchTextController = TextEditingController()
      ..addListener(onSearchQueryChanged);

    context.read<WikiIndexProvider>()
      ..ensureRecentAccessedLoaded()
      ..ensureWikiPagesLoaded();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<ScaffoldProvider>().wikiSearchAppBar = appBar;
      searchTextFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchTextFocusNode.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  void onSearchQueryChanged() {
    setState(() {
      _searchResult = search(_searchTextController.text);
    });
  }

  List<WikiPage> search(String query) {
    if (readWikiIndexProvider.wikiPages.isEmpty) return [];
    if (query.isEmpty) return [];
    final List<WikiPage> result = [];

    query = WikiNetworkGateway.sanitizeForSearch(query);

    for (final page in readWikiIndexProvider.wikiPages) {
      if (page.title
          .replaceAll(RegExp(r'[・、\s]'), '')
          .katakanaized!
          .toLowerCase()
          .contains(query)) {
        result.add(page);
      }
    }
    return result;
  }

  AppBar get appBar {
    return AppBar(
      centerTitle: true,
      title: Container(
        height: 40,
        width: double.maxFinite,
        decoration: BoxDecoration(
            color: context.colorTheme.background.blend(Color(0xFF7F7F7F), 0.3),
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Focus(
            focusNode: searchTextFocusNode,
            child: TextFormField(
              style: TextStyle(
                color: context.colorTheme.primary.blend(Color(0xFF7F7F7F), 0.3),
              ),
              controller: _searchTextController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  fillColor: context.colorTheme.background
                      .blend(Color(0xFF7F7F7F), 0.3),
                  hintText: "ページ名で検索",
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
        ),
      ),
      shape: Border(
          bottom: BorderSide(
              color:
                  context.colorTheme.background.blend(Color(0xFF7F7F7F), 0.3),
              width: 1)),
    );
  }

  void open(WikiPage page) async {
    context.read<WikiIndexProvider>().updateLastAccessedAt(page.title);

    GoRouter.of(context).pushNamed(
      Routes.toName(Routes.searchWikiReadRoute),
      queryParameters: {'wikiTitle': page.title, 'wikiEndpoint': page.endpoint},
    );
  }

  void searchOnWiki(String query) async {
    final encoded = Uri.encodeComponent(query);
    final endpoint = '?cmd=search&word=$encoded&type=AND';

    GoRouter.of(context).pushNamed(
      Routes.toName(Routes.searchWikiReadRoute),
      queryParameters: {'wikiTitle': query, 'wikiEndpoint': endpoint},
    );
  }

  Widget buildWikiPage(WikiPage wikiPage) {
    return ListTile(
      title: Text(
        wikiPage.title,
        style: TextStyle(color: context.colorTheme.primary),
      ),
      onTap: () async {
        open(wikiPage);
      },
    );
  }

  Widget listHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Container(
        alignment: Alignment.centerLeft,
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

  Widget getWidgetAtIndex(
      List<WikiPage> wikiPages, List<WikiPage> recentAccessed, int index) {
    if (recentAccessed.isNotEmpty && _searchTextController.text == "") {
      if (index == 0) return listHeader('最近開いたページ');
      index -= 1;
      if (index < recentAccessed.length) {
        return buildWikiPage(recentAccessed[index]);
      }
      index -= recentAccessed.length;
    }
    if (index < 0) return Container();
    if (_searchTextController.text == "") {
      if (index == 0) return listHeader('ページ一覧');
      index -= 1;
      if (index < wikiPages.length) {
        return buildWikiPage(wikiPages[index]);
      }
      index -= wikiPages.length;
      if (index < 0) return Container();
    }
    if (_searchTextController.text != "") {
      if (index == 0) return listHeader('検索結果');
      index -= 1;
      if (_searchResult.isEmpty) {
        return ListTile(
          title: Text(
            "Wiki内で「${_searchTextController.text}」を検索",
            style: TextStyle(color: context.colorTheme.primary),
          ),
          onTap: () async {
            searchOnWiki(_searchTextController.text);
          },
        );
      }
      if (index < _searchResult.length) {
        return buildWikiPage(_searchResult[index]);
      }
      index -= _searchResult.length;
    }
    return Container();
  }

  int getItemCount(List<WikiPage> wikiPages, List<WikiPage> recentAccessed) {
    int count = 0;
    if (recentAccessed.isNotEmpty && _searchTextController.text == "") {
      count += 1;
      count += recentAccessed.length;
    }
    if (_searchTextController.text == "") {
      count += 1;
      count += wikiPages.length;
    }
    if (_searchTextController.text != "") {
      count += 1;
      count += _searchResult.isEmpty ? 1 : _searchResult.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final recentAccessed = context.select(
        (WikiIndexProvider wikiIndexProvider) =>
            wikiIndexProvider.recentAccessed);
    final wikiPages = context.select(
        (WikiIndexProvider wikiIndexProvider) => wikiIndexProvider.wikiPages);

    return Scaffold(
        body: Scrollbar(
            interactive: true,
            controller: scrollController,
            child: RefreshIndicator.adaptive(
              onRefresh: () async {
                setState(() {
                  _searchResult = search(_searchTextController.text);
                });
              },
              child: ListView.builder(
                controller: scrollController,
                itemExtent: context.textTheme.bodyLarge!.lineHeightPixel! *
                    3 *
                    MediaQuery.of(context).textScaler.scale(1),
                itemCount: getItemCount(wikiPages, recentAccessed),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return getWidgetAtIndex(wikiPages, recentAccessed, index);
                },
              ),
            )));
  }
}
