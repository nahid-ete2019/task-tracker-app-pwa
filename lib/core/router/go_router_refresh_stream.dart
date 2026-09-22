import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts any Stream (here, Supabase's auth state stream) into a
/// [Listenable] so `GoRouter`'s `refreshListenable` re-evaluates redirects
/// whenever the user signs in or out.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
