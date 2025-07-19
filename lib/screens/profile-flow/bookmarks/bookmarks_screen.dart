import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  int _page = 1;
  final int _limit = 5;
  bool _hasMore = true;
  List<Map<String, Map<String, dynamic>>> _bookmarks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final from = (_page - 1) * _limit;
      final response = await Supabase.instance.client
          .from('study_timelines')
          .select(
            '*, explanations(*), free_response_questions(*), multiple_choice_questions(*), topics(*), units(*, classes(*))',
          )
          .eq('bookmark', true)
          .range(from, from + _limit - 1)
          .order('created_at', ascending: false);

      setState(() {
        if (response.isEmpty || response.length < _limit) {
          _hasMore = false;
        }

        _page++;
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
      // body: NotificationListener<ScrollNotification>(
      //   onNotification: (ScrollNotification scrollInfo) {
      //     if (!scrollInfo.metrics.atEdge) return false;
      //     if (scrollInfo.metrics.pixels == 0) return false;
      //     _loadData();
      //     return true;
      //   },
      //   child: ListView.builder(
      //     itemCount: _bookmarks.length + (_hasMore ? 1 : 0),
      //     itemBuilder: (context, index) {
      //       if (index >= _bookmarks.length) {
      //         return const Center(child: CircularProgressIndicator());
      //       }
      //       final bookmark = _bookmarks[index];
      //       return ListTile(title: Text(bookmark.toString()));
      //     },
      //   ),
      // ),
    );
  }
}
