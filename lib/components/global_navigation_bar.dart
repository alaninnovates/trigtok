import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GlobalNavigationBar extends StatelessWidget {
  const GlobalNavigationBar({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey<String>('GlobalNavigationBar'));
  final StatefulNavigationShell navigationShell;

  void onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add), label: 'New'),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            label: 'My Content',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}
