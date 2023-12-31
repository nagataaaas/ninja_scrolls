import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'sqlite.dart';

// param: id
// result: str
// fetch https://note.com/api/v1/notes/:id and return result.data.body
Future<Note> fetchNoteBody(String id, [bool useCache = true]) async {
  if (useCache && await NoteGateway.isCached(id)) {
    log('returning saved $id...');
    return await NoteGateway.load(id);
  }
  log('fetching $id...');
  var url = 'https://note.com/api/v3/notes/$id';
  var response = http.get(Uri.parse(url));
  var json = (await response.then((value) {
    return jsonDecode(utf8.decode(value.bodyBytes));
  }));

  log('fetched $id');
  var episode = Note.fromJson(json);
  log('parsed $id');
  NoteGateway.save(episode);
  log('saved $id');

  return episode;
}
