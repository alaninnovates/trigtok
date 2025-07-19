import 'package:flutter/material.dart';
import 'package:markdown_widget/config/markdown_generator.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:trig_tok/components/markdown/latex.dart';
import 'package:collection/collection.dart';

class McqContainer extends StatefulWidget {
  const McqContainer({
    super.key,
    required this.stimulus,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanations,
    required this.selectedAnswer,
    required this.onAnswerSubmitted,
  });

  final String stimulus;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final List<String> explanations;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSubmitted;

  @override
  State<McqContainer> createState() => _McqContainerState();
}

class _McqContainerState extends State<McqContainer> {
  String? selectedOption;
  int? selectedIndex;
  bool? isSubmitted;
  bool shouldShowStimulus = true;

  @override
  void initState() {
    super.initState();
    if (widget.stimulus.isEmpty) {
      shouldShowStimulus = false;
    }
    if (widget.selectedAnswer != null) {
      print('Selected answer: ${widget.selectedAnswer}');
      selectedOption = widget.options[widget.selectedAnswer!];
      selectedIndex = widget.selectedAnswer;
      isSubmitted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: shouldShowStimulus ? 2 : 1,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  if (shouldShowStimulus) Tab(text: 'Stimulus'),
                  Tab(text: 'Question'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    if (shouldShowStimulus)
                      Padding(
                        padding: const EdgeInsets.all(16),
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBlock(
                              data: widget.question,
                              generator: MarkdownGenerator(
                                generators: [latexGenerator],
                                inlineSyntaxList: [LatexSyntax()],
                                richTextBuilder: (span) => Text.rich(span),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...widget.options.asMap().entries.map((entry) {
                              int index = entry.key;
                              String option = entry.value;
                              return RadioListTile<String>(
                                title: MarkdownBlock(
                                  data: option,
                                  generator: MarkdownGenerator(
                                    generators: [latexGenerator],
                                    inlineSyntaxList: [LatexSyntax()],
                                    richTextBuilder: (span) => Text.rich(span),
                                  ),
                                ),
                                value: option,
                                groupValue: selectedOption,
                                onChanged:
                                    isSubmitted == null
                                        ? (value) {
                                          setState(() {
                                            selectedOption = value;
                                            selectedIndex = index;
                                          });
                                        }
                                        : null,
                              );
                            }),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  selectedOption != null
                                      ? () {
                                        setState(() {
                                          isSubmitted = true;
                                        });
                                        widget.onAnswerSubmitted(
                                          selectedIndex!,
                                        );
                                      }
                                      : null,
                              child: const Text('Submit'),
                            ),
                            if (isSubmitted != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                isSubmitted! &&
                                        selectedIndex == widget.correctAnswer
                                    ? 'Correct!'
                                    : 'Incorrect. The correct answer is option ${widget.correctAnswer + 1}.',
                                style: TextStyle(
                                  color:
                                      isSubmitted! &&
                                              selectedIndex ==
                                                  widget.correctAnswer
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explanations:',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              ...widget.explanations.mapIndexed((
                                i,
                                explanation,
                              ) {
                                return MarkdownBlock(
                                  data: '${i + 1}. $explanation',
                                  generator: MarkdownGenerator(
                                    generators: [latexGenerator],
                                    inlineSyntaxList: [LatexSyntax()],
                                    richTextBuilder: (span) => Text.rich(span),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
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
