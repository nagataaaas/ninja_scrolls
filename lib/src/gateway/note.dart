import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sqlite.dart';

// param: id
// result: str
// fetch https://note.com/api/v1/notes/:id and return result.data.body
Future<Note> fetchNoteBody(String id) async {
  // if (await isEpisodeCached(id)) {
  //   print('returning saved $id...');
  //   return await loadEpisode(id);
  // }
  print('fetching $id...');
  var url = 'https://note.com/api/v3/notes/$id';
  var response = http.get(Uri.parse(url));
  var json = (await response
      .then((value) => jsonDecode(utf8.decode(value.bodyBytes))));
  var episode = Note.fromJson(json['data']);
  // saveEpisode(episode);

  return episode;
}
