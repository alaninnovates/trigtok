import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/study/audio_video_player.dart';
import 'package:trig_tok/components/study/study_state_model.dart';
import 'package:trig_tok/utils/streak_counter.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.userSessionId});

  final int userSessionId;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final PreloadPageController pageController = PreloadPageController();

  @override
  void initState() {
    super.initState();
    print('session ID: ${widget.userSessionId}');
    Supabase.instance.client.functions
        .invoke(
          'start-new-session',
          queryParameters: {'user_session_id': widget.userSessionId.toString()},
          method: HttpMethod.get,
        )
        .then((response) {
          if (response.status == 200) {
            final data = response.data as Map<String, dynamic>;
            print('New session started with ID: ${data['scroll_session_id']}');
            if (mounted) {
              print('Mounted, setting scroll session ID');
              context.read<StudyStateModel>().setScrollSessionId(
                data['scroll_session_id'],
              );
            }
          } else {
            print('Error starting new session: ${response.data}');
          }
        });
  }

  void onPageChanged(int index) {
    print("Scroll callback received with index $index");
    context.read<StudyStateModel>().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<StudyStateModel>().scrollSessionId == '') {
      return const Center(child: CircularProgressIndicator());
    }

    return PreloadPageView.builder(
      scrollDirection: Axis.vertical,
      preloadPagesCount: 1,
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
