import 'package:flutter/widgets.dart';

/// Lets a widget detect when it becomes visible again after a pushed route
/// above it is popped (see [RouteAware.didPopNext]), e.g. to refresh data
/// that may have changed while the user was away.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
