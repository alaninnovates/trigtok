import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';
import 'package:trig_tok/components/page_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GlobalNavigationBar(),
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(
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
                title: Text(
                  Supabase
                          .instance
                          .client
                          .auth
                          .currentUser
                          ?.userMetadata?['email'] ??
                      'No email',
                ),
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
                      print('Sign-out error: $error');
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
