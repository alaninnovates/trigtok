import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class UnitSelection extends StatefulWidget {
  const UnitSelection({super.key, required this.classId});
  final int classId;

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
        .select('id, name, number')
        .eq('class_id', widget.classId)
        .order('number', ascending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Unit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                        title: Text('Unit ${unit['number']}: ${unit['name']}'),
                        onTap: () {
                          GoRouter.of(context).push(
                            '/new/class/${widget.classId}/unit/${unit['id']}',
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
        ),
      ),
    );
  }
}
