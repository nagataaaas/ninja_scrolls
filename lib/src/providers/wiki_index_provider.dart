import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/gateway/database/wiki.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';

class WordSearchResult {
  WikiPage page;
  double matchRate;
  int matchLength;
  WordSearchResult(this.page, this.matchRate, this.matchLength);

  double get score => matchRate * pow(matchLength, 0.5);
}

class WikiIndexProvider extends ChangeNotifier {
  static const recentCount = 10;

  bool _wikiPagesLoaded = false;
  bool _recentAccessedLoaded = false;
  List<WikiPage> _wikiPages = [];
  List<WikiPage> _recentAccessed = [];

  List<WikiPage> get wikiPages => _wikiPages;
  List<WikiPage> get recentAccessed => _recentAccessed;

  List<String> _sanitiziedTexts = [];
  Map<String, List<WikiPage>> _wikiPagesBySanitizedText = {};

  void buildMap() {
    _sanitiziedTexts = List.from(_wikiPages.map((e) => e.sanitizedTitle))
      ..sort();
    _wikiPagesBySanitizedText = groupBy(_wikiPages, (e) => e.sanitizedTitle);
  }

  List<WordSearchResult> findPages(String query) {
    if (_sanitiziedTexts.isEmpty || query.isEmpty) return [];
    final sanitizedQuery = WikiNetworkGateway.sanitizeForSearch(query);
    final sanitizedQueryForCompare =
        WikiNetworkGateway.sanitizeForCompare(query);

    int index = Bisect.findIndexToInsert(_sanitiziedTexts, sanitizedQuery);

    final List<WordSearchResult> result = [];

    int calcMatchLength(String target, String parent) {
      final int targetLength = target.length;
      final int parentLength = parent.length;
      final int minLength =
          targetLength < parentLength ? targetLength : parentLength;
      int matchCount = 0;
      for (int i = 0; i < minLength; i++) {
        if (target[i] != parent[i]) break;
        matchCount++;
      }
      return matchCount;
    }

    double calcMatchRate(String target, String parent) {
      final int targetLength = target.length;
      final int parentLength = parent.length;
      final int maxLength =
          targetLength > parentLength ? targetLength : parentLength;
      return calcMatchLength(target, parent) / maxLength;
    }

    while (index < _sanitiziedTexts.length) {
      bool foundMatch = false;
      for (final page in _wikiPagesBySanitizedText[_sanitiziedTexts[index]]!) {
        final sanitizedTextForCompare =
            WikiNetworkGateway.sanitizeForCompare(page.title);
        if (sanitizedTextForCompare.startsWith(sanitizedQueryForCompare)) {
          result.add(WordSearchResult(
            page,
            calcMatchRate(sanitizedTextForCompare, sanitizedQueryForCompare),
            calcMatchLength(sanitizedTextForCompare, sanitizedQueryForCompare),
          ));
          foundMatch = true;
        }
      }
      if (!foundMatch) break;
      index++;
    }
    return result
      ..sort((a, b) {
        final matchRateCompare = a.matchRate.compareTo(b.matchRate);
        if (matchRateCompare != 0) return matchRateCompare;
        return -a.page.title.length.compareTo(b.page.title.length);
      });
  }

  Future<List<WikiPage>?> ensureWikiPagesLoaded() async {
    if (_wikiPagesLoaded) return _wikiPages;
    _wikiPages = await WikiNetworkGateway.getPages();
    _wikiPagesLoaded = true;
    notifyListeners();
    buildMap();
    return _wikiPages;
  }

  Future<List<WikiPage>?> ensureRecentAccessedLoaded() async {
    if (_recentAccessedLoaded) return _recentAccessed;
    _recentAccessed = await WikiPageTableGateway.recentAccessed(recentCount);
    _recentAccessedLoaded = true;
    notifyListeners();
    return _recentAccessed;
  }

  Future<List<WikiPage>> refreshWikiPages() async {
    _wikiPages = await WikiNetworkGateway.getPages(useCache: false);
    notifyListeners();
    buildMap();
    return _wikiPages;
  }

  Future updateLastAccessedAt(String title) async {
    await WikiPageTableGateway.updateLastAccessedAt(title);
    _recentAccessed = await WikiPageTableGateway.recentAccessed(recentCount);
    notifyListeners();
  }
}

class Bisect {
  static int findIndexToInsert(List<String> list, String target) {
    int left = 0;
    int right = list.length - 1;
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      if (list[mid].compareTo(target) < 0) {
        left = mid + 1;
      } else if (list[mid].compareTo(target) > 0) {
        right = mid - 1;
      } else {
        return mid;
      }
    }
    return left;
  }
}
