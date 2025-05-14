import 'package:flutter/material.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GlobalNavigationBar(),
      body: const Center(child: Text('Study Screen')),
    );
  }
}
