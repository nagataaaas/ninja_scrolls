import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ninja_scrolls/src/providers/user_settings_provider.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/circular_indicator.dart';
import 'package:ninja_scrolls/src/view/components/loading_screen/throwing_shuriken.dart';
import 'package:provider/provider.dart';

Future<bool> createLoadingIndicatorOnSetting(
    BuildContext context, Completer<void> completer) async {
  if (context.read<UserSettingsProvider>().getRichAnimationEnabled(context)) {
    return await createThrowingShuriken(context, completer);
  }
  return await createCircuarIndicator(context, completer);
}
