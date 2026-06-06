import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipify/providers/auth_provider.dart';
import 'package:recipify/providers/user_profile_provider.dart';
import 'package:recipify/screens/profile_setup_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget home;
  const AuthWrapper({super.key, required this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) {
        if (user == null) {
          final showLogin = ref.watch(showLoginProvider);
          return showLogin ? const LoginScreen() : const SignUpScreen();
        }

        final profileAsync = ref.watch(userProfileProvider);

        return profileAsync.when(
          loading: () => const _LoadingScreen(),
          error: (e, _) => Scaffold(
            body: Center(child: Text('Error loading profile: $e')),
          ),
          data: (profile) {
            if (profile == null) return const ProfileSetupScreen();

            return home;
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }
}