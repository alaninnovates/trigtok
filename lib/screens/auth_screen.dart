import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Future<void> _nativeGoogleSignIn() async {
    var iosClientId = dotenv.env['IOS_CLIENT_ID'] ?? '';
    final GoogleSignIn googleSignIn = GoogleSignIn(clientId: iosClientId);
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        GoRouter.of(context).replace('/home');
      }
    });
  }

  Future<void> _webGoogleSignIn() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.platformDefault,
      redirectTo:
          kDebugMode ? 'http://localhost:3000' : 'https://app.trigtok.com',
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        GoRouter.of(context).replace('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    if (isLoggedIn) {
      Future.microtask(() => GoRouter.of(context).replace('/home'));
      return const SizedBox.shrink();
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to TrigTok!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                (!kIsWeb ? _nativeGoogleSignIn() : _webGoogleSignIn())
                    .catchError((error) {
                      log('Sign-in error: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign-in failed: $error')),
                      );
                    });
              },
              child: const Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
