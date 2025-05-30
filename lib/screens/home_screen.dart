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
  final _future = Supabase.instance.client
      .from('user_sessions')
      .select(
        'id, classes(id, name), profiles(study_timelines(units(class_id, name), created_at))',
      );

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
                    print(snapshot.error);
                    return Center(child: const Text('Error loading sessions'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sessions = snapshot.data!;
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
                      // todo: Add logic to determine the last unit studied
                      return Card(
                        child: ListTile(
                          title: Text(sessionsItem['classes']['name']),
                          subtitle: Text('Left off on: Unknown'),
                          onTap: () {
                            GoRouter.of(
                              context,
                            ).push('/study/${sessionsItem['id']}');
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
}
