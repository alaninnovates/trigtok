import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';
import 'package:trig_tok/components/page_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _future = Supabase.instance.client.from('classes').select();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GlobalNavigationBar(),
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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final classes = snapshot.data!;
                  return ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classItem = classes[index];
                      return Card(
                        child: ListTile(
                          title: Text(classItem['name'] ?? 'Unknown Class'),
                          subtitle: Text('Left off on: unknown'),
                          onTap: () {
                            // Handle tap
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
