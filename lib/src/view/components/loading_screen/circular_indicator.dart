import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/navkey.dart';

Future<bool> createCircuarIndicator(Completer<void> completer) async {
  if (completer.isCompleted) return true;
  final Completer<bool> successCompleter = Completer<bool>();
  bool popped = false;

  showDialog<void>(
    context: rootNavigatorKey.currentContext!,
    builder: (context) {
      completer.future.then((value) {
        if (!successCompleter.isCompleted) successCompleter.complete(true);
        if (!popped) {
          popped = true;
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
      return WillPopScope(
        onWillPop: () async {
          if (!successCompleter.isCompleted) successCompleter.complete(false);
          if (!popped) {
            popped = true;
            Navigator.of(context, rootNavigator: true).pop();
          }
          return true;
        },
        child: GestureDetector(
            onTap: () {
              if (!successCompleter.isCompleted) {
                successCompleter.complete(false);
              }
              if (!popped) {
                popped = true;
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: Center(child: CircularProgressIndicator.adaptive())),
      );
    },
  );
  return await successCompleter.future;
}
