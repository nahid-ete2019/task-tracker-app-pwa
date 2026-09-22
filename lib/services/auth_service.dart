import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

/// Thin wrapper around Supabase Auth. Keeps every widget/provider from
/// talking to `Supabase.instance.client.auth` directly (PRD NFR-3).
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isSignedIn => currentUser != null;

  /// Google Sign-In via Supabase OAuth. On web this redirects the browser
  /// through Google and back to whichever origin the app is currently
  /// running on (so this works from localhost during dev and from the
  /// deployed domain in production, without depending on Supabase's Site
  /// URL default); on Android it opens a browser tab and returns via the
  /// app's deep link scheme. The origin used here must be present in
  /// Supabase's Authentication > URL Configuration > Redirect URLs.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : AppConstants.oauthRedirectMobile,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
