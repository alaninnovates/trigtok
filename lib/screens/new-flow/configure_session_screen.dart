import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class ConfigureSessionScreen extends StatefulWidget {
  const ConfigureSessionScreen({
    super.key,
    required this.classId,
    required this.unitId,
    required this.topics,
  });
  final int classId;
  final int unitId;
  final List<int> topics;

  @override
  State<ConfigureSessionScreen> createState() => _ConfigureSessionScreenState();
}

class _ConfigureSessionScreenState extends State<ConfigureSessionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool requireCorrectness = true;
  Map<String, String> questionDisplay = {
    'explanation': 'Explanation',
    'mcq': 'Multiple Choice Questions',
    'frq': 'Free Response Questions',
  };
  List<String> selectedTypes = ['explanation', 'mcq', 'frq'];
  Map<String, int> maxQuestionsPerTopic = {'mcq': 4, 'frq': 2};
  Map<String, int> questionsPerTopic = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageBody(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 8.0,
                  children:
                      questionDisplay.entries
                          .map(
                            (type) => ChoiceChip(
                              label: Text(type.value),
                              selected: selectedTypes.contains(type.key),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add(type.key);
                                  } else {
                                    selectedTypes.remove(type.key);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    title: const Text('Require Correctness'),
                    subtitle: const Text(
                      'Repeat incorrect question types until answered correctly.',
                    ),
                    value: requireCorrectness,
                    onChanged: (value) {
                      setState(() {
                        requireCorrectness = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (selectedTypes.any(
                  (type) => maxQuestionsPerTopic.containsKey(type),
                ))
                  Text(
                    'Questions per Topic',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 12),
                ...selectedTypes.map((type) {
                  if (!maxQuestionsPerTopic.containsKey(type)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            questionDisplay[type]!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue:
                                maxQuestionsPerTopic[type]?.toString(),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                int? parsedValue = int.tryParse(value);
                                if (parsedValue == null || parsedValue <= 0) {
                                  return 'Please enter a valid number';
                                }
                                if (parsedValue > maxQuestionsPerTopic[type]!) {
                                  return 'Cannot exceed ${maxQuestionsPerTopic[type]}';
                                }
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              helperText: 'Max: ${maxQuestionsPerTopic[type]}',
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                int parsedValue = int.parse(value);
                                questionsPerTopic[type] = parsedValue;
                              } else {
                                questionsPerTopic.remove(type);
                              }
                              _formKey.currentState?.validate();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      for (var type in selectedTypes) {
                        if (!questionsPerTopic.containsKey(type) &&
                            selectedTypes.contains(type) &&
                            maxQuestionsPerTopic.containsKey(type)) {
                          questionsPerTopic[type] =
                              maxQuestionsPerTopic[type] ?? 0;
                        } else {
                          questionsPerTopic.remove(type);
                        }
                      }

                      var userSession = await Supabase.instance.client
                          .from('user_sessions')
                          .insert({
                            'profile_id':
                                Supabase.instance.client.auth.currentUser!.id,
                            'class_id': widget.classId,
                            'desired_unit_id': widget.unitId,
                            'require_correctness': requireCorrectness,
                            'question_types': selectedTypes,
                            'questions_per_topic': questionsPerTopic,
                          })
                          .select('id');
                      await Supabase.instance.client
                          .from('user_sessions_topics')
                          .insert(
                            widget.topics
                                .map(
                                  (topicId) => {
                                    'user_session_id': userSession[0]['id'],
                                    'topic_id': topicId,
                                  },
                                )
                                .toList(),
                          );
                      GoRouter.of(
                        context,
                      ).push('/study/${userSession[0]['id']}');
                    },
                    child: const Text('Start Session'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
