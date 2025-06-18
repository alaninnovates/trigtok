import 'package:flutter/material.dart';
import 'package:trig_tok/components/page_body.dart';
import 'package:trig_tok/screens/my-content-flow/new_set_hero.dart';

class MyContentScreen extends StatelessWidget {
  const MyContentScreen({super.key});

  final String _heroTag = 'new-set-hero';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Center(
          child: Text(
            'My Content',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: _heroTag,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewSetHero(heroTag: _heroTag),
              fullscreenDialog: true,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Set'),
      ),
    );
  }
}
