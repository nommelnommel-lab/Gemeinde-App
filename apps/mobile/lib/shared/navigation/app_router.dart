import 'package:flutter/material.dart';

class AppRouter {
  AppRouter(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  Future<T?> push<T>(Widget page) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return Future.value();
    }
    return navigator.push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState?.pop(result);
  }
}

class AppRouterScope extends InheritedWidget {
  const AppRouterScope({
    super.key,
    required this.router,
    required super.child,
  });

  final AppRouter router;

  static AppRouter of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppRouterScope>();
    assert(scope != null, 'No AppRouterScope found in context');
    return scope!.router;
  }

  @override
  bool updateShouldNotify(AppRouterScope oldWidget) {
    return oldWidget.router != router;
  }
}
