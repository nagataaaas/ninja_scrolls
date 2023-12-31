import 'dart:math' as math;

import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:ninja_scrolls/src/gateway/sqlite.dart';
import 'package:ninja_scrolls/src/static/assets.dart';

final emojiParser = EmojiParser();

class Index {
  DateTime? updatedAt;
  List<Chapter> trilogy;
  List<Chapter> aom;

  Index({this.updatedAt, required this.trilogy, required this.aom});
}

class Chapter {
  final int id;
  String title;
  String description;
  List<ChapterChild> chapterChildren;
  String imagePath;

  List<Object?>? encoded;

  Chapter(
      {required this.id,
      required this.title,
      required this.description,
      required this.chapterChildren,
      required this.imagePath});

  EpisodeLink? get firstEpisodeLink {
    for (var chapterChild in chapterChildren) {
      if (chapterChild.isEpisodeLinkGroup) {
        return chapterChild.episodeLinkGroup!.links.first;
      }
    }
    return null;
  }

  List<EpisodeLink> get episodeLinks {
    final List<EpisodeLink> links = [];
    for (var chapterChild in chapterChildren) {
      if (chapterChild.isEpisodeLinkGroup) {
        links.addAll(chapterChild.episodeLinkGroup!.links);
      }
    }
    return links;
  }

  Chapter copyWith({
    String? title,
    String? description,
    List<ChapterChild>? chapterChildren,
    String? imagePath,
  }) {
    return Chapter(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      chapterChildren: chapterChildren ?? this.chapterChildren,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  static Chapter decode(List<Object?> input) {
    return Chapter(
      id: input[0]! as int,
      title: input[1]! as String,
      description: input[2]! as String,
      chapterChildren: (input[3]! as List<Object?>)
          .map((e) => ChapterChild.decode(e! as List<Object?>))
          .toList(),
      imagePath: input[4]! as String,
    );
  }

  List<Object?> encode() {
    encoded ??= [
      'Chapter',
      id,
      title,
      description,
      chapterChildren.map((e) => e.encode()).toList(),
      imagePath,
    ];
    return encoded!;
  }
}

class ChapterChild {
  EpisodeLinkGroup? episodeLinkGroup;
  String? guide;

  bool get isGuide => guide != null;
  bool get isEpisodeLinkGroup => episodeLinkGroup != null;

  ChapterChild({this.episodeLinkGroup, this.guide});
  factory ChapterChild.episodeLinkGroup(EpisodeLinkGroup episodeLinkGroup) {
    return ChapterChild(episodeLinkGroup: episodeLinkGroup);
  }
  factory ChapterChild.guide(String guide) {
    return ChapterChild(guide: guide);
  }

  static ChapterChild decode(List<Object?> input) {
    return ChapterChild(
      episodeLinkGroup: input[1] != null
          ? EpisodeLinkGroup.decode(input[1]! as List<Object?>)
          : null,
      guide: input[2]! as String?,
    );
  }

  List<Object?> encode() {
    return [
      'ChapterChild',
      episodeLinkGroup?.encode(),
      guide,
    ];
  }
}

class EpisodeLinkGroup {
  String? groupName;
  List<EpisodeLink> links;

  EpisodeLinkGroup({this.groupName, required this.links});

  static EpisodeLinkGroup decode(List<Object?> input) {
    return EpisodeLinkGroup(
      groupName: input[0]! as String?,
      links: (input[1]! as List<Object?>)
          .map((e) => EpisodeLink.decode(e! as List<Object?>))
          .toList(),
    );
  }

  List<Object?> encode() {
    return [
      'EpisodeLinkGroup',
      groupName,
      links.map((e) => e.encode()).toList(),
    ];
  }
}

class EpisodeLink {
  String title;
  String noteId;
  String? emoji;

  EpisodeLink({required this.title, required this.noteId, this.emoji});

  static EpisodeLink decode(List<Object?> input) {
    return EpisodeLink(
      title: input[1]! as String,
      noteId: input[2]! as String,
      emoji: input[3]! as String?,
    );
  }

  List<Object?> encode() {
    return [
      'EpisodeLink',
      title,
      noteId,
      emoji,
    ];
  }
}

Index parseChapters(Note note) {
  final updatedAtText = RegExp(r'\d{4}/\d{2}/\d{2}').firstMatch(note.title);
  final udpatedAt = updatedAtText == null
      ? null
      : DateFormat('yyyy/MM/dd').parse(updatedAtText.group(0)!);
  final document = parse(note.html);

  // loop through all elements after first h2
  Element? current = document
      .getElementsByTagName('h2')
      .firstWhere((element) => element.text.contains('ネオサイタマ炎上'));

  final List<List<Element>> chapters = [];

  while (current != null) {
    // trilogy
    if (current.localName == 'h2') {
      if (chapters.length == 3) break;
      chapters.add([current]);
    } else {
      chapters.last.add(current);
    }
    current = current.nextElementSibling;
  }
  current = document
      .getElementsByTagName('h2')
      .firstWhere((element) => element.text.contains('AoM本編'));
  while (current != null && current.localName != 'h3') {
    current = current.nextElementSibling;
  }
  while (current != null) {
    // AoM
    if (current.localName == 'h2') break;
    if (current.localName == 'h3') {
      chapters.add([current]);
    } else {
      chapters.last.add(current);
    }
    current = current.nextElementSibling;
  }

  return Index(
    updatedAt: udpatedAt,
    trilogy: [
      parseNeoSaitama(chapters[0]),
      parseKyotoHell(chapters[1]),
      parseNeverDies(chapters[2]),
    ],
    aom: chapters
        .sublist(3)
        .asMap()
        .map((i, chapter) => MapEntry(i, parseAoM(chapter, i)))
        .values
        .toList(),
  );
}

Chapter parseNeoSaitama(List<Element> nodes) {
  String title = nodes.first.innerHtml.replaceAll(RegExp(r'[◆「」]'), ' ').trim();
  if (title.endsWith('編')) {
    title = title.substring(0, title.length - 1);
  }
  final description =
      nodes[1].innerHtml.trim().replaceAll(RegExp(r'(<br>)+$'), '');

  Element before = nodes[1];
  final List<ChapterChild> chapterChildren = [];
  nodes.sublist(2).forEach((node) {
    final anchors = node.querySelectorAll('a');
    if (anchors.isEmpty) {
      before = node;
      return;
    }
    final groupName = before.text.trim().startsWith('◆')
        ? before.text
            .trim()
            .replaceAll('◆', '')
            .replaceAll('「ネオサイタマ・イン・フレイム】', '【ネオサイタマ・イン・フレイム】')
        : null;
    final links = anchors.map((anchor) {
      final title =
          anchor.text.replaceAllMapped(RegExp(r'[【】]'), (_) => ' ').trim();
      final noteId = RegExp(r'n[0-9a-z]+', caseSensitive: false)
          .matchAsPrefix(anchor.attributes['href']!.split('/').last)!
          .group(0)!;

      return EpisodeLink(title: title, noteId: noteId);
    }).toList();
    chapterChildren.add(ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: groupName, links: links)));

    before = node;
  });

  return Chapter(
    id: 0,
    title: title,
    description: description,
    chapterChildren: chapterChildren,
    imagePath: Assets.bannersNeoSaitamaInFlames,
  );
}

Chapter parseKyotoHell(List<Element> nodes) {
  String title = nodes.first.innerHtml.replaceAll(RegExp(r'[◆「」]'), ' ').trim();
  if (title.endsWith('編')) {
    title = title.substring(0, title.length - 1);
  }
  final description =
      nodes[1].innerHtml.trim().replaceAll(RegExp(r'(<br>)+$'), '');

  final anchors = nodes[2].querySelectorAll('a');
  final links = anchors.map((anchor) {
    final title =
        anchor.text.replaceAllMapped(RegExp(r'[【】]'), (_) => ' ').trim();
    final noteId = RegExp(r'n[0-9a-z]+', caseSensitive: false)
        .matchAsPrefix(anchor.attributes['href']!.split('/').last)!
        .group(0)!;

    return EpisodeLink(title: title, noteId: noteId);
  }).toList();
  final List<ChapterChild> chapterChildren = [
    ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: null, links: links))
  ];

  return Chapter(
    id: 1,
    title: title,
    description: description,
    chapterChildren: chapterChildren,
    imagePath: Assets.bannersKyotoHellOnEarth,
  );
}

Chapter parseNeverDies(List<Element> nodes) {
  String title = nodes.first.innerHtml.replaceAll(RegExp(r'[◆「」]'), ' ').trim();
  if (title.endsWith('編')) {
    title = title.substring(0, title.length - 1);
  }
  final description =
      nodes[1].innerHtml.trim().replaceAll(RegExp(r'(<br>)+$'), '');

  final List<ChapterChild> chapterChildren = [];
  nodes.sublist(2).forEach((node) {
    final anchors = node.querySelectorAll('a');
    if (anchors.isEmpty) {
      if (node.localName == 'figure') {
        String guideText = node.children[0].innerHtml.trim();
        guideText = guideText.replaceAllMapped(
            RegExp(r'<strong>.*?(ガイド).*?</strong>'), (_) => '');
        chapterChildren.add(ChapterChild.guide(guideText));
      }
      return;
    }

    String text = node.text.trim();
    final firstLine = text.split('【').first;
    text = text.replaceAllMapped(RegExp(r'[【】]'), (_) => ' ').trim();
    final groupName =
        firstLine.contains('◆') ? firstLine.replaceAll('◆', ' ').trim() : null;

    final links = anchors.map((anchor) {
      final title =
          anchor.text.replaceAllMapped(RegExp(r'[【】]'), (_) => ' ').trim();
      final titleIndex = text.indexOf(title);
      final previousText = titleIndex > 0
          ? text.substring(math.max(titleIndex - 5, 0), titleIndex).trim()
          : null;
      final emoji = previousText != null && emojiParser.count(previousText) > 0
          ? emojiParser.parseEmojis(previousText).first
          : null;
      final noteId = RegExp(r'n[0-9a-z]+', caseSensitive: false)
          .matchAsPrefix(anchor.attributes['href']!.split('/').last)!
          .group(0)!;
      return EpisodeLink(
        title: title,
        noteId: noteId,
        emoji: emoji,
      );
    }).toList();
    chapterChildren.add(ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: groupName, links: links)));
  });

  return Chapter(
    id: 2,
    title: title,
    description: description,
    chapterChildren: chapterChildren,
    imagePath: Assets.bannersNinjaslayerNeverDies,
  );
}

Chapter parseAoM(List<Element> nodes, int chapterIndex) {
  String title = nodes.first.innerHtml.split('：')[1].trim();
  if (title.endsWith('編')) {
    title = title.substring(0, title.length - 1);
  }
  final description =
      nodes[1].innerHtml.trim().replaceAll(RegExp(r'(<br>)+$'), '');

  final List<ChapterChild> chapterChildren = [];
  nodes.sublist(2).forEach((node) {
    final anchors = node.querySelectorAll('a');
    if (anchors.isEmpty) return;

    final lines = node.innerHtml
        .split(RegExp('(</?br>)|◇'))
        .map((e) => e.replaceAll(RegExp('<.+?>'), '').trim())
        .where((line) => line != '')
        .toList();

    if (lines.length == 1) {
      // slate of ninja
      if (anchors.isEmpty) return;
      chapterChildren.add(ChapterChild.episodeLinkGroup(
          EpisodeLinkGroup(groupName: null, links: [
        EpisodeLink(
          title: anchors.first.text
              .replaceAllMapped(RegExp(r'[【】]'), (_) => ' ')
              .trim(),
          noteId: anchors.first.attributes['href']!
              .split('/')
              .last
              .split('?')
              .first,
          emoji: null,
        )
      ])));
      return;
    }

    String? groupName;
    if (lines.first.contains(anchors.first.text)) {
      groupName = null;
    } else {
      groupName = lines.first.replaceAll('◆', '').trim();
    }

    final links = anchors.map((anchor) {
      String title = lines.firstWhere(
        (line) => line.contains(anchor.text),
        orElse: () => anchor.text,
      );

      title = title.replaceAll('　', '');
      if (title.contains('幕間') || title.contains('コミック')) {
        title = title
            .replaceAllMapped(
                RegExp('[【】「」]'), (m) => '【「'.contains(m[0]!) ? ': ' : '')
            .trim();
      } else if (title.contains('第')) {
        title = title
            .replaceAll('：', '')
            .replaceAllMapped(
                RegExp('[【】「」]'), (m) => '【「'.contains(m[0]!) ? ': ' : '')
            .trim();
      } else if (title.contains('◇')) {
        title = title.replaceAll('◇', '').trim();
      } else {
        title = title.replaceAllMapped(RegExp('[【】「」]'), (_) => ' ').trim();
      }
      title =
          title.replaceAllMapped(RegExp(r'([前後]編)'), (m) => " ${m[0]}").trim();
      final noteId = RegExp(r'n[0-9a-z]+', caseSensitive: false)
          .matchAsPrefix(anchor.attributes['href']!.split('/').last)!
          .group(0)!;
      return EpisodeLink(
        title: title,
        noteId: noteId,
        emoji: null,
      );
    }).toList();
    chapterChildren.add(ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: groupName, links: links)));
  });

  late final String imagePath;
  switch (chapterIndex) {
    case 0:
      imagePath = Assets.bannersNjslyr1;
      break;
    case 1:
      imagePath = Assets.bannersNjslyr2;
      break;
    case 2:
      imagePath = Assets.bannersNjslyr3;
      break;
    case 3:
      imagePath = Assets.bannersNjslyr4;
      break;
    default:
      imagePath = Assets.bannersNjslyr4;
  }

  return Chapter(
    id: 3 + chapterIndex,
    title: "シーズン${chapterIndex + 1}： $title",
    description: description,
    chapterChildren: chapterChildren,
    imagePath: imagePath,
  );
}
