import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:trig_tok/components/study/study_state_model.dart';
import 'package:trig_tok/components/study/transcript_parser.dart';
import 'package:video_player/video_player.dart';

class AudioVideoPlayer extends StatefulWidget {
  const AudioVideoPlayer({super.key, required this.index});
  final int index;

  @override
  State<AudioVideoPlayer> createState() => _AudioVideoPlayerState();
}

class _AudioVideoPlayerState extends State<AudioVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _videoController;
  final _audioPlayer = AudioPlayer();
  final _transcript = TranscriptParser(
    'brainrot_generator/output/unit1_protestant_reformation.srt',
  );
  late List<TranscriptItem> _transcriptItems;
  String currentCaptionText = '';

  @override
  void initState() {
    super.initState();
    print('Initializing AudioVideoPlayer');
    // _videoController = VideoPlayerController.networkUrl(
    //     Uri.parse(
    //       '${dotenv.env['CLOUDFLARE_URL']}/minecraft_${widget.index % 10 + 1}.mp4',
    //     ),
    //   )
    _videoController = VideoPlayerController.asset(
        'brainrot_generator/videos/minecraft_${widget.index % 10 + 1}.mp4',
      )
      ..initialize().then((_) {
        setState(() {});
        if (widget.index == 0) {
          _startPlayback();
        }
      });

    Provider.of<StudyStateModel>(context, listen: false).addListener(() {
      final idx = context.read<StudyStateModel>().index;
      print('StudyStateModel index changed to $idx');
      if (idx != widget.index) {
        return;
      }
      print('Building AudioVideoPlayer $idx');
      _startPlayback();
    });
  }

  Future<void> _startPlayback() async {
    print('Starting playback');
    _videoController.setLooping(true);
    _videoController.setVolume(0.0);
    _videoController.play();
    _transcriptItems = await _transcript.parse();
    _audioPlayer.onPositionChanged.listen((Duration p) {
      for (TranscriptItem item in _transcriptItems) {
        if (item.startTime <= p && item.endTime >= p) {
          setState(() {
            currentCaptionText = item.text;
          });
          break;
        }
      }
    });
    AssetSource source = AssetSource(
      'brainrot_generator/output/unit1_protestant_reformation.mp3',
    );
    _audioPlayer.audioCache = AudioCache(prefix: '');
    await _audioPlayer.play(source);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        _videoController.value.isInitialized
            ? AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            )
            : const CircularProgressIndicator(),
        Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - 50,
          left: 50,
          right: 50,
          child: StrokeText(
            text: currentCaptionText,
            textStyle: TextStyle(fontSize: 30, color: Colors.white),
            strokeColor: Colors.green,
            strokeWidth: 2,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
