import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        Supabase
                                .instance
                                .client
                                .auth
                                .currentUser
                                ?.userMetadata?['avatar_url'] ??
                            'https://gravatar.com/avatar/placeholder',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser
                                    ?.userMetadata?['full_name'] ??
                                'User',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser
                                    ?.userMetadata?['email'] ??
                                Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser
                                    ?.email ??
                                'No email',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text("🔥 "),
                          Text(
                            "7", // todo: streak count
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children:
                    ListTile.divideTiles(
                      context: context,
                      tiles: [
                        ListTile(
                          leading: const Icon(Icons.bookmark_outline),
                          title: const Text('Bookmarks'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/profile/bookmarks'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.star_border_outlined),
                          title: const Text('Subscription'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/profile/subscription'),
                        ),
                      ],
                    ).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Supabase.instance.client.auth
                    .signOut()
                    .then((_) {
                      GoRouter.of(context).replace('/');
                    })
                    .catchError((error) {
                      log('Sign-out error: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign-out failed: $error')),
                      );
                    });
              },
              child: const Text('Sign Out'),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}
