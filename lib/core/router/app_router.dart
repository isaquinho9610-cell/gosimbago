import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/task_detail/task_detail_screen.dart';
import '../../presentation/screens/task_form/task_form_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(child: StatsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/task/new',
      builder: (context, state) => const TaskFormScreen(),
    ),
    GoRoute(
      path: '/task/:id',
      builder: (context, state) => TaskDetailScreen(taskId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/task/:id/edit',
      builder: (context, state) => TaskFormScreen(taskId: state.pathParameters['id']),
    ),
  ],
);
