import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/study/frq_container.dart';
import 'package:trig_tok/components/study/mcq_container.dart';
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
  late List<TranscriptItem> _transcriptItems;
  Map<String, dynamic> sessionElement = {};
  String currentCaptionText = '';

  late StudyStateModel _studyStateModel;

  @override
  void initState() {
    super.initState();
    print('init state for index ${widget.index}');
    _studyStateModel = Provider.of<StudyStateModel>(context, listen: false);
    _studyStateModel.addListener(_studyStateListener);
    _videoController = VideoPlayerController.networkUrl(
        Uri.parse(
          '${dotenv.env['CLOUDFLARE_URL']}/minecraft_${widget.index % 10 + 1}.mp4',
        ),
      )
      ..initialize().then((_) {
        setState(() {});
        if (widget.index == 0) {
          print('starting due to widget index 0');
          _startPlayback();
        }
      });
  }

  Future<void> _startPlayback() async {
    print(
      'Starting playback for index ${widget.index}, scroll session ID: ${_studyStateModel.scrollSessionId}',
    );
    var res = await Supabase.instance.client.functions.invoke(
      'get-session-element',
      queryParameters: {
        'scroll_session_id': _studyStateModel.scrollSessionId.toString(),
        'index': widget.index.toString(),
      },
      method: HttpMethod.get,
    );
    if (res.status != 200) {
      print('Error fetching session element: ${res.data}');
      return;
    }
    final data = res.data as Map<String, dynamic>;
    setState(() {
      sessionElement = data;
    });
    print('Fetched session element: $data');
    print('Starting playback ${_videoController.dataSource}');
    _videoController.setLooping(true);
    _videoController.setVolume(0.0);
    _videoController.play();

    if (data['type'] == 'explanation') {
      _transcriptItems = TranscriptParser.parseTranscript(
        data['data']['transcript'],
      );
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
      _audioPlayer.audioCache = AudioCache(prefix: '');
      UrlSource source = UrlSource(data['data']['audioUrl']);
      await _audioPlayer.play(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        !_videoController.value.isInitialized
            // VIDEO CONTAINER LOADING
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Loading video...",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            )
            // SESSION ELEMENT LOADING
            : sessionElement.isEmpty
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Loading question...",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            )
            // VIDEO CONTAINER DISPLAY
            : AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            ),
        sessionElement.isEmpty
            ? const SizedBox.shrink()
            : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                Flexible(
                  flex: 8,
                  child: Builder(
                    builder: (context) {
                      print('builder!');
                      if (sessionElement.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      if (sessionElement['type'] == 'mcq') {
                        print('building MCQ container');
                        return McqContainer(
                          stimulus: sessionElement['data']['stimulus'],
                          question: sessionElement['data']['question'],
                          options:
                              sessionElement['data']['answers']
                                  .map<String>((e) => e.toString())
                                  .toList(),
                          correctAnswer: int.parse(
                            sessionElement['data']['correctAnswer'],
                          ),
                          explanations:
                              sessionElement['data']['explanations']
                                  .map<String>((e) => e.toString())
                                  .toList(),
                          selectedAnswer:
                              sessionElement['data']['selectedAnswer'],
                          onAnswerSubmitted: (int selectedOptionIndex) async {
                            print(
                              'Selected option index: $selectedOptionIndex',
                            );
                            print(
                              'timeline id: ${sessionElement['timelineId']}',
                            );
                            await Supabase.instance.client
                                .from('study_timelines')
                                .update({
                                  'data': {
                                    'selected_answer': selectedOptionIndex,
                                    'correct':
                                        selectedOptionIndex ==
                                        int.parse(
                                          sessionElement['data']['correctAnswer'],
                                        ),
                                    'scroll_session_id':
                                        _studyStateModel.scrollSessionId,
                                  },
                                })
                                .eq('id', sessionElement['timelineId']);
                          },
                        );
                      } else if (sessionElement['type'] == 'frq') {
                        return FrqContainer(
                          stimulus: sessionElement['data']['stimulus'],
                          questions:
                              (sessionElement['data']['questions'] as List)
                                  .cast<Map<String, dynamic>>(),
                          rubric:
                              sessionElement['data']['rubric']
                                  .map<String>((e) => e.toString())
                                  .toList(),
                          answers:
                              sessionElement['data']['answers'] == null
                                  ? null
                                  : (sessionElement['data']['answers'] as List)
                                      .cast<Map<String, dynamic>>(),
                          onAnswersSubmitted: (
                            List<Map<String, dynamic>> answers,
                          ) async {
                            print('Answers submitted: $answers');
                            print(
                              'timeline id: ${sessionElement['timelineId']}',
                            );
                            int aiGrade = answers.fold<int>(
                              0,
                              (int sum, answer) =>
                                  sum + ((answer['points'] ?? 0) as int),
                            );
                            print('AI grade: $aiGrade');
                            int totalPoints =
                                sessionElement['data']['questions'].fold<int>(
                                  0,
                                  (int sum, question) =>
                                      sum +
                                      ((question['point_value'] ?? 0) as int),
                                );
                            print('total points: $totalPoints');
                            await Supabase.instance.client
                                .from('study_timelines')
                                .update({
                                  'data': {
                                    'answers': answers,
                                    'ai_grade': aiGrade,
                                    'total_points_possible': totalPoints,
                                    'scroll_session_id':
                                        _studyStateModel.scrollSessionId,
                                  },
                                })
                                .eq('id', sessionElement['timelineId']);
                          },
                        );
                      } else if (sessionElement['type'] == 'explanation') {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Center(
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
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Spacer(),
              ],
            ),
        sessionElement.isNotEmpty
            ? Positioned(
              bottom: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.black54,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                          child: Text(
                            sessionElement['unitName'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            sessionElement['topic']['topic'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            : const SizedBox.shrink(),
        sessionElement.isNotEmpty
            ? Positioned(
              bottom: 24,
              right: 24,
              child: IconButton(
                icon:
                    sessionElement['bookmark'] == true
                        ? const Icon(Icons.bookmark, color: Colors.yellow)
                        : const Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                        ),
                onPressed: () async {
                  print(
                    'Bookmarking session element ${sessionElement['timelineId']}',
                  );
                  bool nextBookmarkState =
                      sessionElement['bookmark'] == true ? false : true;
                  setState(() {
                    sessionElement['bookmark'] = nextBookmarkState;
                  });
                  await Supabase.instance.client
                      .from('study_timelines')
                      .update({'bookmark': nextBookmarkState})
                      .eq('id', sessionElement['timelineId']);
                },
              ),
            )
            : const SizedBox.shrink(),
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
