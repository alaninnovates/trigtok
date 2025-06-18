import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _future = Supabase.instance.client.rpc('get_sessions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue where you left off',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error.toString());
                    return Center(child: const Text('Error loading sessions'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sessions = snapshot.data!;
                  print('Sessions: $sessions');
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No sessions found!'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              GoRouter.of(context).go('/new');
                            },
                            child: const Text('Start a new session'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final sessionsItem = sessions[index];
                      return Card(
                        child: ListTile(
                          title: Text(sessionsItem['class_name']),
                          subtitle: Text(
                            'Left off on: ${sessionsItem['last_topic_studied']}',
                          ),
                          trailing: Text(
                            _formatTimeAgo(sessionsItem['last_studied_at']),
                          ),
                          onTap: () {
                            GoRouter.of(
                              context,
                            ).push('/study/${sessionsItem['session_id']}');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
