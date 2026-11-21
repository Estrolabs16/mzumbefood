import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/screens/add_expense.dart';
import 'package:mzumbefood/screens/add_sale.dart';
import 'package:mzumbefood/screens/analytics.dart';
import 'package:mzumbefood/screens/auth/create_account.dart';
import 'package:mzumbefood/screens/auth/forgot_password.dart';
import 'package:mzumbefood/screens/auth/sign_in.dart';
import 'package:mzumbefood/screens/debts.dart';
import 'package:mzumbefood/screens/expense_names.dart';
import 'package:mzumbefood/screens/history.dart';
import 'package:mzumbefood/screens/home.dart';
import 'package:mzumbefood/screens/ingredients.dart';
import 'package:mzumbefood/screens/menu.dart';
import 'package:mzumbefood/screens/mishkaki.dart';
import 'package:mzumbefood/screens/personal_budget.dart';
import 'package:mzumbefood/screens/personal_income.dart';
import 'package:mzumbefood/screens/profile.dart';
import 'package:mzumbefood/screens/sacks.dart';
import 'package:mzumbefood/screens/shell.dart';
import 'package:mzumbefood/screens/splash.dart';

GoRouter buildRouter(AuthProvider auth) {
  const authPaths = ['/sign-in', '/create-account', '/forgot-password'];
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isLoading) return null;
      final location = state.matchedLocation;
      final onAuthPage = authPaths.contains(location);
      if (!auth.isSignedIn && location != '/splash' && !onAuthPage) {
        return '/sign-in';
      }
      if (auth.isSignedIn && (onAuthPage || location == '/splash')) {
        return '/home';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant, size: 70, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Page not found'),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(
        path: '/create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(path: '/debts', builder: (context, state) => const DebtsScreen()),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add-sale',
        builder: (context, state) => AddSaleScreen(
          saleId: state.uri.queryParameters['id'],
          initialDate: state.uri.queryParameters['date'],
        ),
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => AddExpenseScreen(
          expenseId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
      GoRoute(
        path: '/ingredients',
        builder: (context, state) => const IngredientsScreen(),
      ),
      GoRoute(
        path: '/mishkaki',
        builder: (context, state) => const MishkakiScreen(),
      ),
      GoRoute(path: '/sacks', builder: (context, state) => const SacksScreen()),
      GoRoute(
        path: '/expense-names',
        builder: (context, state) => const ExpenseNamesScreen(),
      ),
      GoRoute(
        path: '/personal-budget',
        builder: (context, state) => const PersonalBudgetScreen(),
      ),
      GoRoute(
        path: '/personal-income',
        builder: (context, state) => const PersonalIncomeScreen(),
      ),
    ],
  );
}
