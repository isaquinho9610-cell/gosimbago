import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/auth_screen.dart';

class GoSimbaGoApp extends ConsumerWidget {
  const GoSimbaGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: '국제처 업무관리',
      theme: AppTheme.theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return authState.when(
          data: (state) {
            final session = Supabase.instance.client.auth.currentSession;
            if (session == null) return const AuthScreen();
            return child ?? const SizedBox.shrink();
          },
          loading: () => const Scaffold(
            backgroundColor: Color(0xFF0D1117),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF009DC4))),
          ),
          error: (_, __) => const AuthScreen(),
        );
      },
    );
  }
}
