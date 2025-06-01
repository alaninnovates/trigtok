import 'package:flutter/material.dart';
import 'package:markdown_widget/config/markdown_generator.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:trig_tok/components/markdown/latex.dart';

class McqContainer extends StatefulWidget {
  const McqContainer({
    super.key,
    required this.stimulus,
    required this.question,
    required this.options,
    required this.onOptionSelected,
  });

  final String stimulus;
  final String question;
  final List<String> options;
  final ValueChanged<String> onOptionSelected;

  @override
  State<McqContainer> createState() => _McqContainerState();
}

class _McqContainerState extends State<McqContainer> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(tabs: [Tab(text: 'Stimulus'), Tab(text: 'Question')]),
              Expanded(
                child: TabBarView(
                  children: [
                    // Stimulus Tab
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
                    // Question and Answers Tab
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
                              // style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            ...widget.options.map((option) {
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
                                onChanged: (value) {
                                  setState(() {
                                    selectedOption = value;
                                    widget.onOptionSelected(value!);
                                  });
                                },
                              );
                            }),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  selectedOption != null
                                      ? () {
                                        widget.onOptionSelected(
                                          selectedOption!,
                                        );
                                      }
                                      : null,
                              child: const Text('Submit'),
                            ),
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
