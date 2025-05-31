import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';
import 'package:trig_tok/components/study/study_state_model.dart';
import 'package:trig_tok/screens/auth_screen.dart';
import 'package:trig_tok/screens/home_screen.dart';
import 'package:trig_tok/screens/new-flow/class_selection_screen.dart';
import 'package:trig_tok/screens/new-flow/topic_selection_screen.dart';
import 'package:trig_tok/screens/new-flow/unit_selection_screen.dart';
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
        final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
        if (!isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).replace('/');
          });
          return const SizedBox.shrink();
        }
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
          initialLocation: '/new',
          routes: [
            GoRoute(
              path: '/new',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: ClassSelection()),
              routes: [
                GoRoute(
                  path: 'class/:classId',
                  builder: (context, state) {
                    final classId = state.pathParameters['classId']!;
                    return UnitSelection(classId: int.parse(classId));
                  },
                  routes: [
                    GoRoute(
                      path: 'unit/:unitId',
                      builder: (context, state) {
                        final unitId = state.pathParameters['unitId']!;
                        return TopicSelection(
                          classId: int.parse(state.pathParameters['classId']!),
                          unitId: int.parse(unitId),
                        );
                      },
                    ),
                  ],
                ),
              ],
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
      path: '/study/:userSessionId',
      builder: (BuildContext context, GoRouterState state) {
        return ChangeNotifierProvider(
          create: (context) => StudyStateModel(),
          child: StudyScreen(
            userSessionId: int.parse(state.pathParameters['userSessionId']!),
          ),
        );
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
