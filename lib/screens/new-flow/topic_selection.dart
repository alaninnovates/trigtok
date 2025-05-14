import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicSelection extends StatefulWidget {
  const TopicSelection({
    super.key,
    required this.classId,
    required this.unitId,
    required this.onTopicsSelected,
  });
  final int classId;
  final int unitId;
  final Function(List<String> topics) onTopicsSelected;

  @override
  State<TopicSelection> createState() => _TopicSelectionState();
}

class _TopicSelectionState extends State<TopicSelection> {
  late Future<List<Map<String, dynamic>>> _future;

  List<String> selectedTopics = [];

  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }

  void _initializeFuture() {
    _future = Supabase.instance.client
        .from('units')
        .select('topics')
        .eq('id', widget.unitId);
  }

  void _onTopicSelected(String topic) {
    setState(() {
      if (selectedTopics.contains(topic)) {
        selectedTopics.remove(topic);
      } else {
        selectedTopics.add(topic);
      }
    });
  }

  void _onContinue() {
    widget.onTopicsSelected(selectedTopics);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Select topics', style: Theme.of(context).textTheme.headlineSmall),
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

              final topics = snapshot.data![0]['topics'] as List<dynamic>;
              if (topics.isEmpty) {
                return const Center(child: Text('No topics found.'));
              }

              return ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return CheckboxListTile(
                    title: Text(topic),
                    value: selectedTopics.contains(topic),
                    onChanged: (bool? value) {
                      _onTopicSelected(topic);
                    },
                  );
                },
              );
            },
          ),
        ),
        ElevatedButton(onPressed: _onContinue, child: const Text('Continue')),
      ],
    );
  }
}
