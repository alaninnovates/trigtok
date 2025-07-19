import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class BookmarkedUnits extends StatefulWidget {
  const BookmarkedUnits({super.key, required this.classId});

  final int classId;

  @override
  State<BookmarkedUnits> createState() => _BookmarkedUnitsState();
}

class _BookmarkedUnitsState extends State<BookmarkedUnits> {
  bool _isLoading = false;

  final Map<int, String> _bookmarkedUnits = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('study_timelines')
          .select('units(*, classes(*))')
          .eq('bookmark', true)
          .order('created_at', ascending: false);
      if (response.isEmpty) {
        setState(() {
          _bookmarkedUnits.clear();
        });
        return;
      }
      final unitMap = <int, String>{};
      for (final item in response) {
        final classId = (item['units']['classes']['id'] as int);
        final unitItem = item['units'];
        final unitId = unitItem['id'] as int;
        final unitName = unitItem['name'] as String;
        final unitNumber = unitItem['number'] as int;
        if (!unitMap.containsKey(classId) && widget.classId == classId) {
          unitMap[unitId] = '$unitNumber. $unitName';
        }
      }
      final sortedUnitMap = Map.fromEntries(
        unitMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      setState(() {
        _bookmarkedUnits.clear();
        _bookmarkedUnits.addAll(sortedUnitMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: PageBody(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookmarkedUnits.isEmpty
                ? const Center(child: Text('No bookmarks found'))
                : ListView.builder(
                  itemCount: _bookmarkedUnits.length,
                  itemBuilder: (context, index) {
                    final unitId = _bookmarkedUnits.keys.elementAt(index);
                    final unitName = _bookmarkedUnits[unitId]!;
                    return ListTile(
                      title: Text(unitName),
                      onTap: () {
                        GoRouter.of(context).push(
                          '/profile/bookmarks/class/${widget.classId}/unit/$unitId',
                        );
                      },
                      trailing: const Icon(Icons.arrow_forward),
                    );
                  },
                ),
      ),
    );
  }
}
