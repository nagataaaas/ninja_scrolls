// Flutter imports:
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> readerShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'reader');
final GlobalKey<NavigatorState> wikiShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'wiki');
final GlobalKey<NavigatorState> settingShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'setting');

final GlobalKey episodeSelectorKey = GlobalKey();
final GlobalKey<ScaffoldState> shellScaffoldKey = GlobalKey<ScaffoldState>();
