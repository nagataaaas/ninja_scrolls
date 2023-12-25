import 'package:html/dom.dart';
import 'package:html/parser.dart';

class Chapter {
  String title;
  String? description;
  List<ChapterChild> chapterChildren;

  Chapter(
      {required this.title, this.description, required this.chapterChildren});
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
}

class EpisodeLinkGroup {
  String? groupName;
  List<EpisodeLink> links;

  EpisodeLinkGroup({this.groupName, required this.links});
}

class EpisodeLink {
  String title;
  String noteId;

  EpisodeLink({required this.title, required this.noteId});
}

Chapter parseChapters(String html) {
  final document = parse(html);

  // loop through all elements after first h2
  Element? current = document
      .getElementsByTagName('h2')
      .firstWhere((element) => element.text.contains('ネオサイタマ炎上'));

  final List<List<Element>> chapters = [];

  while (current != null && chapters.length < 3) {
    if (current.localName == 'h2') {
      chapters.add([current]);
    } else {
      chapters.last.add(current);
    }
    current = current.nextElementSibling;
  }

  return parseNeoSaitama(chapters[0]);
}

Chapter parseNeoSaitama(List<Element> nodes) {
  final title = nodes.first.innerHtml.trim().replaceAll('◆', '');
  final description = nodes[1].innerHtml.trim();

  Element before = nodes[1];
  final List<ChapterChild> chapterChildren = [];
  nodes.sublist(2).forEach((node) {
    final anchors = node.querySelectorAll('a');
    if (anchors.isEmpty) {
      before = node;
      return;
    }
    final groupName = before.text.trim().startsWith('◆')
        ? before.text.trim().replaceAll('◆', '')
        : null;
    final links = anchors
        .map((anchor) => EpisodeLink(
            title:
                anchor.text.trim().replaceAllMapped(RegExp(r'[【】]'), (_) => ''),
            noteId:
                anchor.attributes['href']!.split('/').last.split('?').first))
        .toList();
    chapterChildren.add(ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: groupName, links: links)));

    before = node;
  });

  return Chapter(
      title: title, description: description, chapterChildren: chapterChildren);
}

Chapter parseKyotoHell(List<Element> nodes) {
  final title = nodes.first.innerHtml.trim().replaceAll('◆', '');
  final description = nodes[1].innerHtml.trim();

  final anchors = nodes[2].querySelectorAll('a');
  final links = anchors
      .map((anchor) => EpisodeLink(
          title:
              anchor.text.trim().replaceAllMapped(RegExp(r'[【】]'), (_) => ''),
          noteId: anchor.attributes['href']!.split('/').last.split('?').first))
      .toList();
  final List<ChapterChild> chapterChildren = [
    ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: null, links: links))
  ];

  return Chapter(
      title: title, description: description, chapterChildren: chapterChildren);
}

Chapter parseNeverDies(List<Element> nodes) {
  final title = nodes.first.innerHtml.trim().replaceAll('◆', '');
  final description = nodes[1].innerHtml.trim();

  Element before = nodes[1];
  final List<ChapterChild> chapterChildren = [];
  nodes.sublist(2).forEach((node) {
    final anchors = node.querySelectorAll('a');
    if (anchors.isEmpty) {
      before = node;
      return;
    }
    final groupName = before.text.trim().startsWith('◆')
        ? before.text.trim().replaceAll('◆', '')
        : null;
    final links = anchors
        .map((anchor) => EpisodeLink(
            title:
                anchor.text.trim().replaceAllMapped(RegExp(r'[【】]'), (_) => ''),
            noteId:
                anchor.attributes['href']!.split('/').last.split('?').first))
        .toList();
    chapterChildren.add(ChapterChild.episodeLinkGroup(
        EpisodeLinkGroup(groupName: groupName, links: links)));

    before = node;
  });

  return Chapter(
      title: title, description: description, chapterChildren: chapterChildren);
}
