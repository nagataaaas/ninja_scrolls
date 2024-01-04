import 'package:flutter/material.dart';

class ScaffoldProvider extends ChangeNotifier {
  String? _episodeTitle;
  String? _wikiTitle;
  AppBar? _episodeSearchAppBar;
  AppBar? _wikiSearchAppBar;
  Widget? _endDrawer;

  String? get episodeTitle => _episodeTitle;
  String? get wikiTitle => _wikiTitle;
  AppBar? get episodeSearchAppBar => _episodeSearchAppBar;
  AppBar? get wikiSearchAppBar => _wikiSearchAppBar;
  Widget? get endDrawer => _endDrawer;

  set endDrawer(Widget? value) {
    _endDrawer = value;
    notifyListeners();
  }

  set episodeTitle(String? value) {
    _episodeTitle = value;
    notifyListeners();
  }

  set wikiTitle(String? value) {
    _wikiTitle = value;
    notifyListeners();
  }

  set episodeSearchAppBar(AppBar? value) {
    _episodeSearchAppBar = value;
    notifyListeners();
  }

  set wikiSearchAppBar(AppBar? value) {
    _wikiSearchAppBar = value;
    notifyListeners();
  }
}
