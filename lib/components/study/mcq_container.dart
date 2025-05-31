import 'package:flutter/material.dart';

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
                        child: Text(
                          widget.stimulus,
                          style: Theme.of(context).textTheme.bodyLarge,
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
                            Text(
                              widget.question,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            ...widget.options.map((option) {
                              return RadioListTile<String>(
                                title: Text(option),
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
