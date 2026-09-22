import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Matches the reference "Your Life, Organized in One Place" welcome
/// screen: a short pitch and a single primary sign-in action.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 44),
              ),
              const SizedBox(height: 32),
              Text(
                'Your Life, Organized\nin One Place',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 28, height: 1.25),
              ),
              const SizedBox(height: 14),
              const Text(
                'Track your goals, manage your tasks, and see your progress — all in one beautiful dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _signIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.login, size: 20),
                  label: Text(_loading ? 'Signing in…' : 'Continue with Google'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing you agree to sync your Planner data to your Google account via Supabase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
