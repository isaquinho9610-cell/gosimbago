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
    final isLoggedIn = authState.whenOrNull(
          data: (_) => Supabase.instance.client.auth.currentSession != null,
        ) ??
        false;

    if (!isLoggedIn) {
      return MaterialApp(
        title: '국제처 업무관리',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const AuthScreen(),
      );
    }

    return MaterialApp.router(
      title: '국제처 업무관리',
      theme: AppTheme.theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
