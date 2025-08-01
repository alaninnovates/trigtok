import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/global_navigation_bar.dart';
import 'package:trig_tok/components/study/study_state_model.dart';
import 'package:trig_tok/screens/auth_screen.dart';
import 'package:trig_tok/screens/home_screen.dart';
import 'package:trig_tok/screens/new-flow/class_selection_screen.dart';
import 'package:trig_tok/screens/new-flow/configure_session_screen.dart';
import 'package:trig_tok/screens/new-flow/topic_selection_screen.dart';
import 'package:trig_tok/screens/new-flow/unit_selection_screen.dart';
import 'package:trig_tok/screens/profile-flow/bookmarks/bookmarked_classes.dart';
import 'package:trig_tok/screens/profile-flow/bookmarks/bookmarked_units.dart';
import 'package:trig_tok/screens/profile-flow/bookmarks/bookmarks_screen.dart';
import 'package:trig_tok/screens/profile-flow/profile_screen.dart';
import 'package:trig_tok/screens/my-content-flow/my_content_screen.dart';
import 'package:trig_tok/screens/profile-flow/subscription_screen.dart';
import 'package:trig_tok/screens/study_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
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
                      routes: [
                        GoRoute(
                          path: 'configure',
                          builder: (context, state) {
                            if (state.extra == null ||
                                state.pathParameters['classId'] == null ||
                                state.pathParameters['unitId'] == null) {
                              return const SizedBox.shrink();
                            }
                            final topics =
                                (state.extra as Map<String, dynamic>)['topics'];
                            return ConfigureSessionScreen(
                              classId: int.parse(
                                state.pathParameters['classId']!,
                              ),
                              unitId: int.parse(
                                state.pathParameters['unitId']!,
                              ),
                              topics: topics,
                            );
                          },
                        ),
                      ],
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
              path: '/my-content',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: MyContentScreen()),
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
              routes: [
                GoRoute(
                  path: '/bookmarks',
                  pageBuilder:
                      (context, state) =>
                          const MaterialPage(child: BookmarkedClasses()),
                  routes: [
                    GoRoute(
                      path: 'class/:classId',
                      builder: (context, state) {
                        final classId = state.pathParameters['classId']!;
                        return BookmarkedUnits(classId: int.parse(classId));
                      },
                      routes: [
                        GoRoute(
                          path: 'unit/:unitId',
                          builder: (context, state) {
                            final unitId = state.pathParameters['unitId']!;
                            final classId = state.pathParameters['classId']!;
                            return BookmarksScreen(
                              classId: int.parse(classId),
                              unitId: int.parse(unitId),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: '/subscription',
                  builder: (context, state) {
                    return const SubscriptionScreen();
                  },
                ),
              ],
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
    // GoRoute(
    //   path: '/success',
    //   builder: (context, state) {
    //     final queryParams = state.pathParameters;
    //     final priceId = queryParams['price_id'];
    //     final transactionId = queryParams['transaction_id'];
    //     final customerEmail = queryParams['customer_email'];
    //     final paddleCustomerId = queryParams['paddle_customer_id'];
    //   },
    // ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrigTok',
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
