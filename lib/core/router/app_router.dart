import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/goals/add_edit_goal_screen.dart';
import '../../screens/goals/goals_screen.dart';
import '../../screens/habits/add_edit_habit_screen.dart';
import '../../screens/habits/habits_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/tasks/add_edit_task_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const tasks = '/tasks';
  static const addTask = '/tasks/add';
  static const editTask = '/tasks/edit';
  static const habits = '/habits';
  static const addHabit = '/habits/add';
  static const editHabit = '/habits/edit';
  static const goals = '/goals';
  static const addGoal = '/goals/add';
  static const editGoal = '/goals/edit';
  static const analytics = '/analytics';
  static const profile = '/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = Supabase.instance.client.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final signedIn = Supabase.instance.client.auth.currentSession != null;
      final loggingIn = state.matchedLocation == AppRoutes.login;
      final atSplash = state.matchedLocation == AppRoutes.splash;

      if (atSplash) return null; // splash decides its own next route
      if (!signedIn && !loggingIn) return AppRoutes.login;
      if (signedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.addTask, builder: (context, state) => const AddEditTaskScreen()),
      GoRoute(
        path: AppRoutes.editTask,
        builder: (context, state) => AddEditTaskScreen(task: state.extra as dynamic),
      ),
      GoRoute(path: AppRoutes.addHabit, builder: (context, state) => const AddEditHabitScreen()),
      GoRoute(
        path: AppRoutes.editHabit,
        builder: (context, state) => AddEditHabitScreen(habit: state.extra as dynamic),
      ),
      GoRoute(path: AppRoutes.addGoal, builder: (context, state) => const AddEditGoalScreen()),
      GoRoute(
        path: AppRoutes.editGoal,
        builder: (context, state) => AddEditGoalScreen(goal: state.extra as dynamic),
      ),
      GoRoute(path: AppRoutes.analytics, builder: (context, state) => const AnalyticsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.tasks, builder: (context, state) => const TasksScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.habits, builder: (context, state) => const HabitsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.goals, builder: (context, state) => const GoalsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
