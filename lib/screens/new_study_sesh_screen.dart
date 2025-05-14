import 'package:flutter/material.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';

class NewStudySeshScreen extends StatelessWidget {
  const NewStudySeshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GlobalNavigationBar(),
      body: const Center(child: Text('New Study Session Screen')),
    );
  }
}
