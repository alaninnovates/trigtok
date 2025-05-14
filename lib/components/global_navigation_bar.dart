import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GlobalNavigationBar extends StatefulWidget {
  const GlobalNavigationBar({super.key});

  @override
  State<GlobalNavigationBar> createState() => _GlobalNavigationBarState();
}

class _GlobalNavigationBarState extends State<GlobalNavigationBar> {
  final List<String> pages = ['/home', '/new', '/search', '/profile'];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      onDestinationSelected: (int index) {
        GoRouter.of(context).replace(pages[index]);
      },
      selectedIndex:
          !pages.contains(
                GoRouter.of(context).routeInformationProvider.value.uri.path,
              )
              ? 0
              : pages.indexOf(
                GoRouter.of(context).routeInformationProvider.value.uri.path,
              ),
      destinations: const <Widget>[
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.add), label: 'New'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
