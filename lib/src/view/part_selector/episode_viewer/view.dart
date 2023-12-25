// import 'package:flutter/material.dart';
// import '../../components/progress_indicator.dart';
// import '../../../gateway/note.dart';

// // arguments
// //   note_id: str
// // view:
// //   show createProgressIndicator whlie buildNote(note_id): Future<String>
// //   show note body

// class NoteViewer extends StatelessWidget {
//   const NoteViewer({super.key, required this.noteId});
//   final String noteId;

//   @override
//   Widget build(BuildContext context) {
//     var noteId = this.noteId;
//     var noteBody = buildNote(noteId);
//     return Scaffold(
//       body: FutureBuilder(
//         future: noteBody,
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             return ListView(children: [
//               Text(snapshot.data!.id),
//               Text(snapshot.data!.title),
//               Text(snapshot.data!.html),
//             ]);
//           } else if (snapshot.hasError) {
//             return Text('${snapshot.error}');
//           }
//           return createProgressIndicator();
//         },
//       ),
//     );
//   }
// }
