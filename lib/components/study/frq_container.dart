import 'package:flutter/material.dart';

class FrqContainer extends StatefulWidget {
  const FrqContainer({
    super.key,
    required this.stimulus,
    required this.questions,
    required this.onAnswersSubmitted,
  });

  final String stimulus;
  final List<String> questions;
  final ValueChanged<List<String>> onAnswersSubmitted;

  @override
  State<FrqContainer> createState() => _FrqContainerState();
}

class _FrqContainerState extends State<FrqContainer> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
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
          length: widget.questions.length + 1,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Stimulus'),
                  ...widget.questions.map((q) => Tab(text: q)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Stimulus Tab
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                widget.stimulus,
                                style: Theme.of(context).textTheme.bodyLarge,
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
                    // Questions Tabs
                    ...widget.questions.map((question) {
                      final index = widget.questions.indexOf(question);
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              question,
                              style: Theme.of(context).textTheme.bodyLarge,
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
                            ElevatedButton(
                              onPressed: () {
                                if (index < widget.questions.length - 1) {
                                  DefaultTabController.of(
                                    context,
                                  ).animateTo(index + 2);
                                } else {
                                  final answers =
                                      _controllers.map((c) => c.text).toList();
                                  widget.onAnswersSubmitted(answers);
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
