import 'dart:async';

import 'package:flutter/material.dart';

Future<bool> createCircuarIndicator(
    BuildContext context, Completer<void> completer) async {
  if (completer.isCompleted) return true;
  final Completer<bool> successCompleter = Completer<bool>();
  bool popped = false;

  void ensurePopped(BuildContext context) {
    if (!popped) {
      popped = true;
      Navigator.of(context).pop();
    }
  }

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return PopScope(
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (!successCompleter.isCompleted) successCompleter.complete(false);
          ensurePopped(context);
        },
        child: GestureDetector(
            onTap: () {
              if (!successCompleter.isCompleted) {
                successCompleter.complete(false);
              }
              ensurePopped(context);
            },
            child: Center(child: CircularProgressIndicator.adaptive())),
      );
    },
  );
  return await successCompleter.future;
}
