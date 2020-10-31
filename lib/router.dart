import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Animations/custom_transition_page.dart';
import 'package:Animations/home.dart';
import 'package:Animations/search_page.dart';
import 'package:animations/animations.dart';
import 'router_provider.dart';

const String _homePageLocation = '/home';
const String _searchPageLocation = '/search';

class ReplyRouterDelegate extends RouterDelegate<ReplyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReplyRoutePath> {
  ReplyRouterDelegate({@required this.replyState})
      : assert(replyState != null),
        navigatorKey = GlobalObjectKey<NavigatorState>(replyState) {
    replyState.addListener(() {
      notifyListeners();
    });
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  RouterProvider replyState;

  @override
  void dispose() {
    replyState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  ReplyRoutePath get currentConfiguration => replyState.routePath;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouterProvider>.value(value: replyState),
      ],
      child: Selector<RouterProvider, ReplyRoutePath>(
        selector: (context, routerProvider) => routerProvider.routePath,
        builder: (context, routePath, child) {
          return Navigator(
            key: navigatorKey,
            onPopPage: _handlePopPage,
            pages: [
              // TODO: Add Shared Z-Axis transition from search icon to search view page (Motion)
              const SharedAxisTransitionPageWrapper(
                transitionKey: ValueKey('Home'),
                screen: HomePage(),
              ),
              if (routePath is ReplySearchPath)
                const SharedAxisTransitionPageWrapper(
                  transitionKey: ValueKey('Search'),
                  screen: SearchPage(),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    // _handlePopPage should not be called on the home page because the
    // PopNavigatorRouterDelegateMixin will bubble up the pop to the
    // SystemNavigator if there is only one route in the navigator.
    assert(route.willHandlePopInternally ||
        replyState.routePath is ReplySearchPath);

    final bool didPop = route.didPop(result);
    if (didPop) replyState.routePath = const ReplyHomePath();
    return didPop;
  }

  @override
  Future<void> setNewRoutePath(ReplyRoutePath configuration) {
    assert(configuration != null);
    replyState.routePath = configuration;
    return SynchronousFuture<void>(null);
  }
}

@immutable
abstract class ReplyRoutePath {
  const ReplyRoutePath();
}

class ReplyHomePath extends ReplyRoutePath {
  const ReplyHomePath();
}

class ReplySearchPath extends ReplyRoutePath {
  const ReplySearchPath();
}

class SharedAxisTransitionPageWrapper extends Page {
  const SharedAxisTransitionPageWrapper(
      {@required this.screen, @required this.transitionKey})
      : assert(screen != null),
        assert(transitionKey != null),
        super(key: transitionKey);

  final Widget screen;
  final ValueKey transitionKey;

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
        settings: this,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            fillColor: Theme.of(context).cardColor,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.scaled,
            child: child,
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          return screen;
        });
  }
}

class ReplyRouteInformationParser
    extends RouteInformationParser<ReplyRoutePath> {
  @override
  Future<ReplyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final url = Uri.parse(routeInformation.location);

    if (url.path == _searchPageLocation) {
      return SynchronousFuture<ReplySearchPath>(const ReplySearchPath());
    }

    return SynchronousFuture<ReplyHomePath>(const ReplyHomePath());
  }

  @override
  RouteInformation restoreRouteInformation(ReplyRoutePath configuration) {
    if (configuration is ReplyHomePath) {
      return RouteInformation(location: _homePageLocation);
    }
    if (configuration is ReplySearchPath) {
      return RouteInformation(location: _searchPageLocation);
    }
    return null;
  }
}
