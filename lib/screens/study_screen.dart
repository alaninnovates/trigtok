import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final PageController pageController = PageController();

  void onPageChanged(int index) {
    print("Scroll callback received with index $index");
    context.read<StudyStateModel>().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: pageController,
      onPageChanged: onPageChanged,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          color: Colors.black,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: Center(
            child: AudioVideoPlayer(
              // key: Key('audio_video_player'),
              index: index,
            ),
          ),
        );
      },
    );
  }
}
