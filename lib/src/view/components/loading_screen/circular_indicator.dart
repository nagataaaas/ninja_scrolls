import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/navkey.dart';

Future<bool> createCircuarIndicator(Completer<void> completer) async {
  if (completer.isCompleted) return true;
  final Completer<bool> successCompleter = Completer<bool>();
  bool popped = false;

  void ensurePopped(NavigatorState navigator) {
    if (!popped) {
      popped = true;
      navigator.pop();
    }
  }

  showDialog<void>(
    context: rootNavigatorKey.currentContext!,
    builder: (dialogContext) {
      final navigator = Navigator.of(dialogContext);
      completer.future.then((value) {
        if (!successCompleter.isCompleted) successCompleter.complete(true);
        ensurePopped(navigator);
      });
      return PopScope(
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (!successCompleter.isCompleted) successCompleter.complete(false);
          ensurePopped(navigator);
        },
        child: GestureDetector(
            onTap: () {
              if (!successCompleter.isCompleted) {
                successCompleter.complete(false);
              }
              ensurePopped(navigator);
            },
            child: Center(child: CircularProgressIndicator.adaptive())),
      );
    },
  );
  return await successCompleter.future;
}
