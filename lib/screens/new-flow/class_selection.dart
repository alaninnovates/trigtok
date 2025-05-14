import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassSelection extends StatefulWidget {
  const ClassSelection({super.key, required this.onClassSelected});
  final Function(int id, String name) onClassSelected;

  @override
  State<ClassSelection> createState() => _ClassSelectionState();
}

class _ClassSelectionState extends State<ClassSelection> {
  final _future = Supabase.instance.client.from('classes').select('id, name');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Start a new session',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search classes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final classes =
                  snapshot.data!
                      .where(
                        (classItem) => classItem['name'].toLowerCase().contains(
                          _searchQuery,
                        ),
                      )
                      .toList();
              if (classes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Text('No classes found!')],
                  ),
                );
              }
              return ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classItem = classes[index];
                  return ListTile(
                    title: Text(classItem['name']),
                    onTap: () {
                      widget.onClassSelected(
                        classItem['id'],
                        classItem['name'],
                      );
                    },
                    trailing: const Icon(Icons.arrow_forward),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
