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

class _AudioVideoPlayerState extends State<AudioVideoPlayer> {
  late VideoPlayerController _videoController;
  final _audioPlayer = AudioPlayer();
  final _transcript = TranscriptParser(
    'brainrot_generator/output/unit1_protestant_reformation.srt',
  );
  late List<TranscriptItem> _transcriptItems;
  String currentCaptionText = '';

  late StudyStateModel _studyStateModel;

  @override
  void initState() {
    super.initState();
    print('init state for index ${widget.index}');
    _studyStateModel = Provider.of<StudyStateModel>(context, listen: false);
    _studyStateModel.addListener(_studyStateListener);
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
          print('starting due to widget index 0');
          _startPlayback();
        }
      });

    final studyStateModel = Provider.of<StudyStateModel>(
      context,
      listen: false,
    );
    studyStateModel.addListener(_studyStateListener);
  }

  Future<void> _startPlayback() async {
    print('Starting playback ${_videoController.dataSource}');
    _videoController.setLooping(true);
    _videoController.setVolume(0.0);
    _videoController.play();
    _transcriptItems = await _transcript.parse();
    print('listening');
    _audioPlayer.onPositionChanged.listen((Duration p) {
      for (TranscriptItem item in _transcriptItems) {
        if (item.startTime <= p && item.endTime >= p) {
          if (currentCaptionText == item.text) {
            return;
          }
          setState(() {
            currentCaptionText = item.text;
          });
          break;
        }
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {});
    print('playing audio');
    _audioPlayer.audioCache = AudioCache(prefix: '');
    AssetSource source = AssetSource(
      'brainrot_generator/output/unit1_protestant_reformation.mp3',
    );
    // UrlSource source = UrlSource('https://doggo.ninja/xF5veu.mp3');
    await _audioPlayer.play(source);
    print('done playing');
  }

  @override
  Widget build(BuildContext context) {
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
            textStyle: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w600,
            ),
            strokeColor: Colors.green,
            strokeWidth: 4,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void dispose() {
    print('disposing ${widget.index}');
    _studyStateModel.removeListener(_studyStateListener);
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _studyStateListener() {
    if (!mounted) return;
    final idx = context.read<StudyStateModel>().index;
    print('StudyStateModel index changed to $idx');
    if (idx != widget.index) {
      return;
    }
    print('Building AudioVideoPlayer $idx');
    _startPlayback();
  }
}
