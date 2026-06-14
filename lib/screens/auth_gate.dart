import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'root_scaffold.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const _AuthLoading();
    }
    if (auth.user == null) {
      return const LoginScreen();
    }

    // LibraryProvider lives above MaterialApp and is rebound to the current
    // user by the proxy provider in main.dart. We just wait for its stream
    // to deliver the first snapshot before revealing the app.
    final library = context.watch<LibraryProvider>();
    if (!library.loaded) {
      return const _AuthLoading();
    }
    return const RootScaffold();
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg : AppColors.lightBg;
    return Scaffold(
      backgroundColor: bg,
      body: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ),
    );
  }
}
