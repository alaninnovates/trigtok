import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/markdown/latex.dart';

class FrqContainer extends StatefulWidget {
  const FrqContainer({
    super.key,
    required this.stimulus,
    required this.questions,
    required this.rubric,
    required this.answers,
    required this.onAnswersSubmitted,
  });

  final String stimulus;
  final List<Map<String, dynamic>> questions;
  final List<String> rubric;
  final List<Map<String, dynamic>>? answers;
  final ValueChanged<List<Map<String, dynamic>>> onAnswersSubmitted;

  @override
  State<FrqContainer> createState() => _FrqContainerState();
}

class _FrqContainerState extends State<FrqContainer> {
  final List<TextEditingController> _controllers = [];
  bool isGrading = false;
  List<Map<String, dynamic>> aiResponses = [];
  bool shouldShowStimulus = true;

  @override
  void initState() {
    super.initState();
    if (widget.stimulus.isEmpty) {
      shouldShowStimulus = false;
    }
    if (widget.answers != null) {
      aiResponses = widget.answers!;
    }
    _controllers.addAll(widget.questions.map((_) => TextEditingController()));
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: widget.questions.length + (shouldShowStimulus ? 1 : 0),
          child: Column(
            children: [
              if (isGrading)
                const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              if (isGrading) const SizedBox(height: 8),
              TabBar(
                tabs: [
                  if (shouldShowStimulus) Tab(text: 'Stimulus'),
                  ...widget.questions.map((q) => Tab(text: q['text'])),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    if (shouldShowStimulus)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: MarkdownBlock(
                                  data: widget.stimulus,
                                  generator: MarkdownGenerator(
                                    generators: [latexGenerator],
                                    inlineSyntaxList: [LatexSyntax()],
                                    richTextBuilder: (span) => Text.rich(span),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                DefaultTabController.of(context).animateTo(1);
                              },
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ),
                    ...widget.questions.map((question) {
                      final index = widget.questions.indexOf(question);
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${question['point_value']} points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            MarkdownBlock(
                              data: question['text'],
                              generator: MarkdownGenerator(
                                generators: [latexGenerator],
                                inlineSyntaxList: [LatexSyntax()],
                                richTextBuilder: (span) => Text.rich(span),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TextField(
                                controller: _controllers[index],
                                maxLines: null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            if (aiResponses.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Grade: ${aiResponses[index]['points']} / ${question['point_value']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          aiResponses[index]['points'] == 0
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Feedback: ${aiResponses[index]['feedback']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ElevatedButton(
                              onPressed: () async {
                                if (isGrading) return;
                                if (index < widget.questions.length - 1) {
                                  DefaultTabController.of(
                                    context,
                                  ).animateTo(index + 2);
                                } else {
                                  final answers =
                                      _controllers.map((c) => c.text).toList();
                                  final combinedAnswers =
                                      answers.asMap().entries.map((entry) {
                                        final i = entry.key;
                                        final answer = entry.value;
                                        return {
                                          'question':
                                              widget.questions[i]['text'],
                                          'answer': answer,
                                          'point_value':
                                              widget
                                                  .questions[i]['point_value'],
                                          'rubric': widget.rubric[i],
                                        };
                                      }).toList();
                                  print('Submitting answers: $combinedAnswers');
                                  setState(() {
                                    isGrading = true;
                                  });
                                  var res = await Supabase
                                      .instance
                                      .client
                                      .functions
                                      .invoke(
                                        'grade-frq',
                                        body: {'answers': combinedAnswers},
                                      );
                                  if (res.status != 200) {
                                    print(
                                      'Error fetching session element: ${res.data}',
                                    );
                                    return;
                                  }
                                  final data =
                                      (res.data as List<dynamic>)
                                          .map((e) => e as Map<String, dynamic>)
                                          .toList();
                                  print('Grading response: $data');
                                  setState(() {
                                    isGrading = false;
                                    aiResponses = data;
                                  });
                                  widget.onAnswersSubmitted(data);
                                }
                              },
                              child: Text(
                                index < widget.questions.length - 1
                                    ? 'Next'
                                    : 'Submit',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
