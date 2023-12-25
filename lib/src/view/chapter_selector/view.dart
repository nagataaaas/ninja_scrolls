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
            final result = parseChapters(snapshot.data!.html);
            print("title: ${result.title}");
            print("description: ${result.description}");
            result.episodeLinkGroups.forEach((group) {
              print("group: ${group.groupName}");
              group.links.forEach((link) {
                print("  link: ${link.title}(${link.noteId})");
              });
            });
            return Container();
          } else {
            return Container();
          }
        });
  }
}
