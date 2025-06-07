import 'dart:developer';

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
        'id, classes(id, name), profiles(study_timelines(topics(topic), created_at))',
      )
      .order(
        'created_at',
        ascending: false,
        referencedTable: 'profiles.study_timelines',
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
                    print(snapshot.error.toString());
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
                      String lastTopic =
                          sessionsItem['profiles']['study_timelines'].isNotEmpty
                              ? sessionsItem['profiles']['study_timelines'][0]['topics']['topic']
                              : 'Unknown';

                      return Card(
                        child: ListTile(
                          title: Text(sessionsItem['classes']['name']),
                          subtitle: Text('Left off on: $lastTopic'),
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
