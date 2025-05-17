import 'package:flutter/material.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Center(child: Text('Study Screen')));
  }
}
