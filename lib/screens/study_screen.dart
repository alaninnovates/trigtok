import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';
import 'package:trig_tok/components/study/audio_video_player.dart';
import 'package:trig_tok/components/study/study_state_model.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.classId,
    required this.unitId,
    required this.topics,
  });

  final String classId;
  final int unitId; // if == -1, then refer to previous topic studied
  final List<String> topics;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final Controller _controller;

  @override
  void initState() {
    super.initState();
    _controller = Controller();

    _controller.addListener((event) async {
      print(
        "Scroll callback received with data: {direction: ${event.direction}, success: ${event.success} and index: ${event.pageNo ?? 'not given'}}",
      );
      if (event.success != ScrollSuccess.SUCCESS) {
        return;
      }
      context.read<StudyStateModel>().setIndex(event.pageNo ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TikTokStyleFullPageScroller(
      contentSize: 100,
      swipePositionThreshold: 0.2,
      swipeVelocityThreshold: 2000,
      animationDuration: const Duration(milliseconds: 100),
      controller: _controller,
      builder: (BuildContext context, int index) {
        return Container(
          color: Colors.black,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: AudioVideoPlayer(
              key: Key('audio_video_player'),
              index: index,
            ),
          ),
        );
      },
    );
  }
}
