import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';
import 'package:trig_tok/components/page_body.dart';
import 'package:trig_tok/screens/new-flow/class_selection.dart';
import 'package:trig_tok/screens/new-flow/topic_selection.dart';
import 'package:trig_tok/screens/new-flow/unit_selection.dart';

class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  int classId = 0;
  String className = '';
  int unitId = 0;
  String unitName = '';
  List<String> topics = [];

  late Widget activeScreen = ClassSelection(
    onClassSelected: (int id, String name) {
      setState(() {
        classId = id;
        className = name;
        activeScreen = UnitSelection(
          classId: classId,
          onUnitSelected: (int id, String name) {
            setState(() {
              unitId = id;
              unitName = name;
              activeScreen = TopicSelection(
                classId: classId,
                unitId: unitId,
                onTopicsSelected: (List<String> selectedTopics) {
                  setState(() {
                    topics = selectedTopics;
                  });
                  GoRouter.of(context).replace(
                    '/study',
                    extra: {
                      'classId': classId,
                      'className': className,
                      'unitId': unitId,
                      'unitName': unitName,
                      'topics': topics,
                    },
                  );
                },
              );
            });
          },
        );
      });
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GlobalNavigationBar(),
      body: PageBody(child: activeScreen),
    );
  }
}
