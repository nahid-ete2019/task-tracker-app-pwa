/// App-wide static constants: task/habit/goal categories, priority and
/// status labels, and the OAuth redirect scheme used for native sign-in.
class AppConstants {
  AppConstants._();

  static const String appName = 'Planner';

  /// Deep link scheme registered in android/app/src/main/AndroidManifest.xml
  /// for the Supabase OAuth callback on Android. On web, Supabase redirects
  /// back to the app's own origin instead, so this is only used natively.
  static const String oauthRedirectMobile = 'io.nahid.tasktracker://login-callback';

  static const List<String> taskCategories = [
    'Work',
    'Personal',
    'Health',
    'Learning',
    'Finance',
    'Other',
  ];

  static const List<String> taskPriorities = ['low', 'medium', 'high'];

  static const List<String> taskStatuses = ['todo', 'in_progress', 'completed'];

  static const List<String> goalCategories = [
    'Career',
    'Health',
    'Finance',
    'Learning',
    'Personal',
    'Travel',
  ];

  static const List<String> habitFrequencies = ['daily', 'weekly', 'custom'];
}
