import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';
import 'package:trig_tok/screens/auth_screen.dart';
import 'package:trig_tok/screens/home_screen.dart';
import 'package:trig_tok/screens/new-flow/new_screen.dart';
import 'package:trig_tok/screens/profile_screen.dart';
import 'package:trig_tok/screens/search_screen.dart';
import 'package:trig_tok/screens/study_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthScreen();
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return GlobalNavigationBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/new',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: NewScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: SearchScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: 'study/:classId',
      builder: (BuildContext context, GoRouterState state) {
        final classId = state.pathParameters['classId']!;
        print('Class ID: $classId');
        if (state.extra != null) {
          final extra = state.extra as Map<String, dynamic>;
          final unitId = extra['unitId'] as int;
          final topics = extra['topics'] as List<String>;
          print('Unit ID: $unitId');
          print('Topics: $topics');
        }
        return StudyScreen(classId: classId);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
