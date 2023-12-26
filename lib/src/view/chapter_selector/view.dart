import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/note_ids.dart';

class ChapterSelectorView extends StatefulWidget {
  const ChapterSelectorView({super.key});

  @override
  State<ChapterSelectorView> createState() => _ChapterSelectorViewState();
}

class _ChapterSelectorViewState extends State<ChapterSelectorView> {
  @override
  void initState() {
    super.initState();
  }

  void parseChapterList(String body) {}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchNoteBody(NoteIds.toc),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            parseChapters(snapshot.data!.html).forEach((result) {
              print("title: ${result.title}");
              print("description: ${result.description}");
              result.chapterChildren.forEach((group) {
                if (group.isEpisodeLinkGroup) {
                  print("group: ${group.episodeLinkGroup!.groupName}");
                  group.episodeLinkGroup!.links.forEach((link) {
                    print(
                        "  link: [${link.emoji}]${link.title}(${link.noteId})");
                  });
                } else {
                  print("guide: ${group.guide!}");
                }
              });
            });
            return Container();
          } else {
            return Container();
          }
        });
  }
}
