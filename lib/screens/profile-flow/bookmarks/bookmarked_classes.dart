import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class BookmarkedClasses extends StatefulWidget {
  const BookmarkedClasses({super.key});

  @override
  State<BookmarkedClasses> createState() => _BookmarkedClassesState();
}

class _BookmarkedClassesState extends State<BookmarkedClasses> {
  bool _isLoading = false;

  final Map<int, String> _bookmarkedClasses = {};

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
          _bookmarkedClasses.clear();
        });
        return;
      }
      final classMap = <int, String>{};
      for (final item in response) {
        final classItem = item['units']['classes'];
        final classId = classItem['id'] as int;
        final className = classItem['name'] as String;
        if (!classMap.containsKey(classId)) {
          classMap[classId] = className;
        }
      }
      setState(() {
        _bookmarkedClasses.clear();
        _bookmarkedClasses.addAll(classMap);
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
                : _bookmarkedClasses.isEmpty
                ? const Center(child: Text('No bookmarks found'))
                : ListView.builder(
                  itemCount: _bookmarkedClasses.length,
                  itemBuilder: (context, index) {
                    final classId = _bookmarkedClasses.keys.elementAt(index);
                    final className = _bookmarkedClasses[classId]!;
                    return ListTile(
                      title: Text(className),
                      onTap: () {
                        GoRouter.of(
                          context,
                        ).push('/profile/bookmarks/class/$classId');
                      },
                      trailing: const Icon(Icons.arrow_forward),
                    );
                  },
                ),
      ),
    );
  }
}
