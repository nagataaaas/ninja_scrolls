import 'dart:developer';

import 'package:flutter/widgets.dart';

final MyNavigatorObserver readShellRouteObserver = MyNavigatorObserver();

class MyNavigatorObserver extends NavigatorObserver {
  List<Route> _history = [];

  bool hasOnStack(String routeName) {
    return _history.any((element) => element.settings.name == routeName);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    String? previous;
    if (previousRoute == null) {
      previous = 'null';
    } else {
      previous = previousRoute.settings.name;
    }
    log(route.settings.toString());
    log('push: Current:${route.settings.name}  Previous:$previous');
    _history.add(route);
    log(_history.map((e) => e.settings.name).toList().toString());
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    String? previous;
    if (previousRoute == null) {
      previous = 'null';
    } else {
      previous = previousRoute.settings.name!;
    }
    log('pop: Current:${route.settings.name}  Previous:$previous');
    _history.remove(route);
    log(_history.map((e) => e.settings.name).toList().toString());
  }
}
