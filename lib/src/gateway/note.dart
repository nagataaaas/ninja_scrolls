import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:ninja_scrolls/src/gateway/database/note.dart';

// param: id
// result: str
// fetch https://note.com/api/v1/notes/:id and return result.data.body
Future<Note> fetchNoteBody(String id,
    {bool useCache = true, bool readNow = false}) async {
  if (useCache && await NoteGateway.isCached(id)) {
    log('returning saved $id...');
    final note = await NoteGateway.load(id);
    if (readNow) {
      note.recentReadAt = DateTime.now();
      NoteGateway.save(note);
    }
    return note;
  }
  log('fetching $id...');
  final url = 'https://note.com/api/v3/notes/$id';
  final response = http.get(Uri.parse(url));
  final json = (await response.then((value) {
    return jsonDecode(utf8.decode(value.bodyBytes));
  }));

  final note = Note.fromJson(json);
  if (readNow) {
    note.recentReadAt = DateTime.now();
  }
  NoteGateway.save(note);

  return note;
}
