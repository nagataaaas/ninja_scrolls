import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
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
  List<WikiPage> _recentAccessed = [];
  List<WikiPage> _wikiPages = [];
  List<WikiPage> _searchResult = [];
  late final FocusNode searchTextFocusNode;
  late final ScrollController scrollController = ScrollController();

  static const recentCount = 10;

  @override
  void initState() {
    super.initState();
    searchTextFocusNode = FocusNode();
    _searchTextController = TextEditingController()
      ..addListener(onSearchQueryChanged);

    WikiNetworkGateway.getPages().then((value) {
      setState(() {
        _wikiPages = value;
      });
    });
    WikiPageTableGateway.recentAccessed(recentCount).then((value) {
      setState(() {
        _recentAccessed = value;
      });
    });

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
    if (_wikiPages.isEmpty) return [];
    if (query.isEmpty) return [];
    final List<WikiPage> result = [];

    query = query.replaceAll(RegExp('[・、]'), '').katakanaized!.toLowerCase();

    for (final page in _wikiPages) {
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
    WikiPageTableGateway.updateLastAccessedAt(page.title);

    WikiPageTableGateway.recentAccessed(recentCount).then((value) {
      if (mounted) {
        setState(() {
          _recentAccessed = value;
        });
      }
    });

    if (!mounted) return;
    GoRouter.of(context).pushNamed(
      Routes.toName(Routes.searchWikiReadRoute),
      queryParameters: {'wikiTitle': page.title, 'wikiEndpoint': page.endpoint},
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

  Widget getWidgetAtIndex(int index) {
    if (_recentAccessed.isNotEmpty && _searchTextController.text == "") {
      if (index == 0) return listHeader('最近開いたページ');
      index -= 1;
      if (index < _recentAccessed.length) {
        return buildWikiPage(_recentAccessed[index]);
      }
      index -= _recentAccessed.length;
    }
    if (index < 0) return Container();
    if (_searchTextController.text == "") {
      if (index == 0) return listHeader('ページ一覧');
      index -= 1;
      if (index < _wikiPages.length) {
        return buildWikiPage(_wikiPages[index]);
      }
      index -= _wikiPages.length;
      if (index < 0) return Container();
    }
    if (_searchTextController.text != "") {
      if (index == 0) return listHeader('検索結果');
      index -= 1;
      if (index < _searchResult.length) {
        return buildWikiPage(_searchResult[index]);
      }
      index -= _searchResult.length;
    }
    return Container();
  }

  int get itemCount {
    int count = 0;
    if (_recentAccessed.isNotEmpty && _searchTextController.text == "") {
      count += 1;
      count += _recentAccessed.length;
    }
    if (_searchTextController.text == "") {
      count += 1;
      count += _wikiPages.length;
    }
    if (_searchTextController.text != "") {
      count += 1;
      count += _searchResult.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Scrollbar(
            controller: scrollController,
            child: RefreshIndicator.adaptive(
              onRefresh: () async {
                _wikiPages = await WikiNetworkGateway.getPages();
                _recentAccessed =
                    await WikiPageTableGateway.recentAccessed(recentCount);
                setState(() {
                  _searchResult = search(_searchTextController.text);
                });
              },
              child: ListView.builder(
                controller: scrollController,
                itemExtent: context.textTheme.bodyLarge!.lineHeightPixel! * 2,
                itemCount: itemCount,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return getWidgetAtIndex(index);
                },
              ),
            )));
  }
}
