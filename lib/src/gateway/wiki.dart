import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';

class WikiNetworkGateway {
  static const baseUrl = 'https://wikiwiki.jp';
  static const njslyrBaseUrl = '/njslyr/';
  static const _listUrl = '$baseUrl$njslyrBaseUrl?cmd=list';

  WikiNetworkGateway._();
  static final instance = WikiNetworkGateway._();

  List<WikiPage>? _pages;

  static bool isContentTitle(String title) {
    if (title.contains("◆")) return false; // wiki original
    if (title.startsWith('コメント')) return false; // wiki comment
    if (title.startsWith('テスト') || title.startsWith('test')) {
      return false; // test page
    }
    if (title.startsWith('編集会議ログ')) return false; // wiki original
    if (title.startsWith('InterWiki')) return false; // wiki original
    if ([
      '旧wikiからの移行メモ',
      'm',
      'SandBox',
      'SideBar',
      'SideMenu',
      'Glossary',
      'RecentCreated',
      'RecentDeleted',
      'MenuBar',
      'FrontPage',
      'BracketName',
      '人気100',
      '今日100',
      '更新履歴',
      '相談所',
      '関連ハッシュタグ等',
      '雑談場'
    ].contains(title)) return false;

    return true;
  }

  static String getEndpoint(String url) {
    return url.startsWith(baseUrl)
        ? url.substring(baseUrl.length)
        : url.startsWith(njslyrBaseUrl)
            ? url.substring(njslyrBaseUrl.length)
            : url;
  }

  static String getUrl(String endpoint) {
    return endpoint.startsWith(baseUrl)
        ? endpoint
        : '$baseUrl$njslyrBaseUrl$endpoint';
  }

  static List<String> splitTitle(String title) {
    if (title.startsWith('「')) return [title];
    if (title.contains('／')) return title.split('／');
    return [title];
  }

  static String sanitizeForSearch(String title) {
    return title
        .replaceAll(RegExp(r'[！! <>＝=＜＞・、/／「」]'), '')
        .katakanaized!
        .toLowerCase();
  }

  static String sanitizeForCompare(String title) {
    return title.replaceAll(RegExp(r'[！! <>＝=＜＞・、/／「」]'), '').toLowerCase();
  }

  static Future<List<WikiPage>> getPages(
      {bool useCache = true, bool useDatabase = true}) async {
    if (!useCache || instance._pages == null) {
      if (useDatabase && await WikiPageTableGateway.isCached) {
        print('cached');
        instance._pages = await WikiPageTableGateway.all;
      } else {
        final response = await http.get(Uri.parse(_listUrl));
        final document = parse(response.body);
        final links =
            document.querySelectorAll('#content > ul > li > ul > li > a');
        final List<WikiPage> pages = [];
        final Map<String, int> titleCount = {};
        for (var link in links) {
          final title = link.text;
          final endpoint = link.attributes['href']!;
          if (isContentTitle(title)) {
            for (var splittedTitle in splitTitle(title)) {
              if (titleCount.containsKey(splittedTitle)) {
                titleCount[splittedTitle] = titleCount[splittedTitle]! + 1;
                splittedTitle = '$splittedTitle (${titleCount[splittedTitle]})';
              } else {
                titleCount[splittedTitle] = 1;
              }
              pages.add(WikiPage(
                  title: splittedTitle,
                  sanitizedTitle: sanitizeForSearch(splittedTitle),
                  endpoint: getEndpoint(endpoint)));
            }
          }
        }
        WikiPageTableGateway.save(pages);
        instance._pages = pages;
      }
    }
    return instance._pages!;
  }
}
