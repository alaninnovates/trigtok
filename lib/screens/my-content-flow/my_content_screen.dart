import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';
import 'package:trig_tok/screens/my-content-flow/delete_set_dialog.dart';
import 'package:trig_tok/screens/my-content-flow/new_set_hero.dart';

class MyContentScreen extends StatefulWidget {
  const MyContentScreen({super.key});

  @override
  State<MyContentScreen> createState() => _MyContentScreenState();
}

class _MyContentScreenState extends State<MyContentScreen> {
  final String _heroTag = 'new-set-hero';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your Sets', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future: Supabase.instance.client
                    .from('sets')
                    .select('id, created_at, title, subject, content, files')
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error.toString());
                    return Center(child: const Text('Error loading sets'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sets = snapshot.data!;
                  if (sets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No sets found!'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          NewSetHero(heroTag: _heroTag),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                            child: const Text('Create a new set'),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: sets.length,
                    itemBuilder: (context, index) {
                      final set = sets[index];
                      final createdAt =
                          DateTime.parse(set['created_at']).toLocal();
                      final formattedDate =
                          '${createdAt.month}/${createdAt.day}/${createdAt.year}';

                      final content = set['content'] as String? ?? '';

                      final files = set['files'] as List? ?? [];

                      return Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      set['title'],
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => DeleteSetDialog(),
                                      );
                                      if (confirmed == true) {
                                        await Supabase.instance.client
                                            .from('sets')
                                            .delete()
                                            .eq('id', set['id']);
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  set['subject'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Created: $formattedDate',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Text(
                                  content,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.attachment,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${files.length}',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: _heroTag,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewSetHero(heroTag: _heroTag),
              fullscreenDialog: true,
            ),
          );
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('New Set'),
      ),
    );
  }
}
