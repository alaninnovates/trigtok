import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/fast_scroll_physics.dart';
import 'package:trig_tok/components/study/audio_video_player.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    required this.classId,
    required this.unitId,
  });

  final int classId;
  final int unitId;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final PreloadPageController pageController = PreloadPageController();

  @override
  void initState() {
    super.initState();
  }

  void onPageChanged(int index) {
    print("Scroll callback received with index $index");
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(child: Text('item $index')),
        );
      },
    );
  }
}
