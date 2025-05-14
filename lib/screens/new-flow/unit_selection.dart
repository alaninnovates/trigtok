import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitSelection extends StatefulWidget {
  const UnitSelection({
    super.key,
    required this.classId,
    required this.onUnitSelected,
  });
  final int classId;
  final Function(int id, String name) onUnitSelected;

  @override
  State<UnitSelection> createState() => _UnitSelectionState();
}

class _UnitSelectionState extends State<UnitSelection> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }

  void _initializeFuture() {
    _future = Supabase.instance.client
        .from('units')
        .select('id, name')
        .eq('class_id', widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Select a unit', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final units = snapshot.data!;
              if (units.isEmpty) {
                return const Center(child: Text('No units found.'));
              }
              return ListView.builder(
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return ListTile(
                    title: Text(unit['name']),
                    onTap: () {
                      widget.onUnitSelected(unit['id'], unit['name']);
                    },
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
