import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class TopicSelection extends StatefulWidget {
  const TopicSelection({
    super.key,
    required this.classId,
    required this.unitId,
  });
  final int classId;
  final int unitId;

  @override
  State<TopicSelection> createState() => _TopicSelectionState();
}

class _TopicSelectionState extends State<TopicSelection> {
  late Future<List<Map<String, dynamic>>> _future;

  List<int> selectedTopics = [];

  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }

  void _initializeFuture() {
    _future = Supabase.instance.client
        .from('topics')
        .select('id, topic')
        .eq('unit_id', widget.unitId)
        .order('id', ascending: true);
  }

  void _onTopicSelected(int topic) {
    setState(() {
      if (selectedTopics.contains(topic)) {
        selectedTopics.remove(topic);
      } else {
        selectedTopics.add(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select topics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No topics available'));
                  }

                  final topics = snapshot.data!;
                  return ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return CheckboxListTile(
                        title: Text(topic['topic']),
                        value: selectedTopics.contains(topic['id']),
                        onChanged: (bool? value) {
                          _onTopicSelected(topic['id']);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (selectedTopics.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one topic.'),
                    ),
                  );
                } else {
                  var userSession = await Supabase.instance.client
                      .from('user_sessions')
                      .insert({
                        'profile_id':
                            Supabase.instance.client.auth.currentUser!.id,
                        'class_id': widget.classId,
                        'desired_unit_id': widget.unitId,
                      })
                      .select('id');
                  await Supabase.instance.client
                      .from('profiles_classes')
                      .upsert({
                        'profile_id':
                            Supabase.instance.client.auth.currentUser!.id,
                        'class_id': widget.classId,
                      });
                  await Supabase.instance.client
                      .from('user_sessions_topics')
                      .insert(
                        selectedTopics
                            .map(
                              (topicId) => {
                                'user_session_id': userSession[0]['id'],
                                'topic_id': topicId,
                              },
                            )
                            .toList(),
                      );
                  GoRouter.of(context).push('/study/${userSession[0]['id']}');
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
