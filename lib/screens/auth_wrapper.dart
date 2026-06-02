import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipify/providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget home; // your main app screen
  const AuthWrapper({super.key, required this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) {
        if (user == null) {
          final showLogin = ref.watch(showLoginProvider);
          return showLogin ? const LoginScreen() : const SignUpScreen();
        }

        return home;
      }
    );
  }
}