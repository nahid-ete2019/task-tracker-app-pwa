import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

/// Live stream of Supabase auth state (sign in / sign out / token refresh).
/// go_router listens to this (via a ChangeNotifier bridge in app_router.dart)
/// to redirect between the Login screen and the Main shell.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The current Supabase user, derived from the auth stream so it updates
/// reactively without a manual refresh.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.whenOrNull(data: (state) => state.session?.user) ?? Supabase.instance.client.auth.currentUser;
});

/// The signed-in user's profile row (name/avatar/email), created
/// automatically by the `handle_new_user` DB trigger on first sign-in.
final profileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileServiceProvider).fetchProfile(user.id);
});
