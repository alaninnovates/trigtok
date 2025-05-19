import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';

class StudyScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Controller controller = Controller();

    controller.addListener((event) {
      _handleCallbackEvent(event.direction, event.success);
    });

    return TikTokStyleFullPageScroller(
      contentSize: 100,
      swipePositionThreshold: 0.2,
      swipeVelocityThreshold: 2000,
      animationDuration: const Duration(milliseconds: 100),
      controller: controller,
      builder: (BuildContext context, int index) {
        return Container(
          color: Colors.black,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Text(
              'Skibidi $index',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCallbackEvent(
    ScrollDirection direction,
    ScrollSuccess success, {
    int? currentIndex,
  }) async {
    print(
      "Scroll callback received with data: {direction: $direction, success: $success and index: ${currentIndex ?? 'not given'}}",
    );
    await Supabase.instance.client.functions.invoke('next-study-step');
  }
}
