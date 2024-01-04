import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/note_ids.dart';

class IndexProvider extends ChangeNotifier {
  Index? _index;

  Index? get index => _index;

  Future<Index> loadIndex() async {
    _index ??=
        await fetchNoteBody(NoteIds.toc).then((value) => parseChapters(value));
    notifyListeners();
    return _index!;
  }

  Future<Index> refreshIndex() async {
    _index = await fetchNoteBody(NoteIds.toc, false)
        .then((value) => parseChapters(value));
    notifyListeners();
    return _index!;
  }

  EpisodeLink? getEpisodeLinkFromNoteId(String noteId) {
    final index = this.index;
    if (index == null) return null;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (ChapterChild child in chapter.chapterChildren) {
        if (!child.isEpisodeLinkGroup) {
          continue;
        }
        for (EpisodeLink link in child.episodeLinkGroup!.links) {
          if (link.noteId == noteId) {
            return link;
          }
        }
      }
    }
    return null;
  }

  int? getChapterIdFromEpisodeNoteId(String noteId) {
    final index = this.index;
    if (index == null) return -1;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (ChapterChild child in chapter.chapterChildren) {
        if (!child.isEpisodeLinkGroup) {
          continue;
        }
        for (EpisodeLink link in child.episodeLinkGroup!.links) {
          if (link.noteId == noteId) {
            return chapter.id;
          }
        }
      }
    }
    return -1;
  }

  Chapter? getChapterById(int id) {
    final index = this.index;
    if (index == null) return null;

    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      if (chapter.id == id) {
        return chapter;
      }
    }
    return null;
  }

  EpisodeLink? previous(EpisodeLink episode) {
    final index = this.index;
    if (index == null) return null;
    EpisodeLink? previous;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (ChapterChild child in chapter.chapterChildren) {
        if (!child.isEpisodeLinkGroup) {
          continue;
        }
        for (EpisodeLink link in child.episodeLinkGroup!.links) {
          if (link.noteId == episode.noteId) {
            return previous;
          }
          previous = link;
        }
      }
    }
    return null;
  }

  EpisodeLink? next(EpisodeLink episode) {
    final index = this.index;
    if (index == null) return null;
    bool found = false;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (ChapterChild child in chapter.chapterChildren) {
        if (!child.isEpisodeLinkGroup) {
          continue;
        }
        for (EpisodeLink link in child.episodeLinkGroup!.links) {
          if (found) {
            return link;
          }
          found = link.noteId == episode.noteId;
        }
      }
    }
    return null;
  }
}
