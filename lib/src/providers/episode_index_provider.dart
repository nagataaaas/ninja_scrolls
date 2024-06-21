import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/gateway/note.dart';
import 'package:ninja_scrolls/src/services/parser/parse_chapters.dart';
import 'package:ninja_scrolls/src/static/note_ids.dart';

class EpisodeIndexProvider extends ChangeNotifier {
  Index? _index;

  Index? get index => _index;

  Future<Index> loadIndex() async {
    if (_index == null) {
      _index = await fetchNoteBody(NoteIds.toc)
          .then((value) => parseChapters(value));
      notifyListeners();
    }
    return _index!;
  }

  Future<Index> refreshIndex() async {
    _index = await fetchNoteBody(NoteIds.toc, useCache: false)
        .then((value) => parseChapters(value));
    notifyListeners();
    return _index!;
  }

  EpisodeLink? getEpisodeLinkFromNoteId(String noteId) {
    final index = this.index;
    if (index == null) return null;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (EpisodeLink link in chapter.episodeLinks) {
        if (link.noteId == noteId) {
          return link;
        }
      }
    }
    return null;
  }

  List<EpisodeLink?> getEpisodeLinksByNoteIds(List<String> noteIds) {
    final index = this.index;
    if (index == null) return [];
    final result = List<EpisodeLink?>.filled(noteIds.length, null);
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (EpisodeLink link in chapter.episodeLinks) {
        if (noteIds.contains(link.noteId)) {
          result[noteIds.indexOf(link.noteId)] = link;
        }
      }
    }
    return result;
  }

  int? getChapterIdbyEpisodeNoteId(String noteId) {
    final index = this.index;
    if (index == null) return -1;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (EpisodeLink link in chapter.episodeLinks) {
        if (link.noteId == noteId) {
          return chapter.id;
        }
      }
    }
    return -1;
  }

  Map<String, int> getChapterIdbyEpisodeNoteIds(List<String> noteIds) {
    final index = this.index;
    if (index == null) return {};
    final result = <String, int>{};
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (EpisodeLink link in chapter.episodeLinks) {
        if (noteIds.contains(link.noteId)) {
          result[link.noteId] = chapter.id;
        }
      }
    }
    return result;
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
      for (EpisodeLink link in chapter.episodeLinks) {
        if (link.noteId == episode.noteId) {
          return previous;
        }
        previous = link;
      }
    }
    return null;
  }

  EpisodeLink? next(EpisodeLink episode) {
    final index = this.index;
    if (index == null) return null;
    bool found = false;
    for (Chapter chapter in [...index.trilogy, ...index.aom]) {
      for (EpisodeLink link in chapter.episodeLinks) {
        if (found) {
          return link;
        }
        found = link.noteId == episode.noteId;
      }
    }
    return null;
  }
}
