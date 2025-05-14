import 'package:flutter/material.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GlobalNavigationBar(),
      body: const Center(child: Text('Profile Screen')),
    );
  }
}
