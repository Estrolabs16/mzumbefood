import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/providers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final signedIn = context.read<AuthProvider>().isSignedIn;
      context.go(signedIn ? '/home' : '/sign-in');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.blueSoft, AppColors.accentSoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logow.png', width: 190, height: 190)
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 26),
            Text(
              S.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ).animate().fadeIn(delay: 180.ms, duration: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            const Text(
              'Sales • Expenses • Debts\nFor your food business',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 260.ms, duration: 300.ms),
            const SizedBox(height: 38),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
