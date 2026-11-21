import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/auth.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/providers.dart';
import 'package:provider/provider.dart';

typedef TestSeeder = void Function(InMemoryRepository repository);

Future<({InMemoryRepository repository, DataStore store, AuthProvider auth, DataProvider data})> pumpScreen(
  WidgetTester tester,
  Widget child, {
  TestSeeder? seed,
  AppUser user = const AppUser(
    uid: 'test-uid',
    email: 'owner@example.com',
    displayName: 'Test Owner',
  ),
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = InMemoryRepository();
  seed?.call(repository);
  final store = DataStore(repository);
  final authService = FakeAuthService();
  final auth = AuthProvider(authService);
  authService.emit(user);
  final data = DataProvider(store);

  addTearDown(data.dispose);
  addTearDown(auth.dispose);
  addTearDown(authService.dispose);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<DataStore>.value(value: store),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<DataProvider>.value(value: data),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1200));
  return (
    repository: repository,
    store: store,
    auth: auth,
    data: data,
  );
}
