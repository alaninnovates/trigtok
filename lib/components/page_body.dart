import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });
  final Widget child;
  final EdgeInsets padding;
  bool canPop(BuildContext context) {
    final lastMatch =
        GoRouter.of(
          context,
        ).routerDelegate.currentConfiguration.matches.lastOrNull;

    if (lastMatch is ShellRouteMatch) {
      return lastMatch.matches.length == 1;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop(context),
      child: SafeArea(child: Padding(padding: padding, child: child)),
    );
  }
}
