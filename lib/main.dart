import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/router.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/auth.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/firebase_options.dart';
import 'package:mzumbefood/providers.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (_) {
    debugPrint('Firestore persistence unavailable on this platform.');
  }
  final authService = FirebaseAuthService(FirebaseAuth.instance);
  final dataStore = DataStore(
    CurrentUserRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
  );
  runApp(
    MultiProvider(
      providers: [
        Provider<DataStore>.value(value: dataStore),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
      ],
      child: const MuFoodApp(),
    ),
  );
}

class MuFoodApp extends StatefulWidget {
  const MuFoodApp({super.key});

  @override
  State<MuFoodApp> createState() => _MuFoodAppState();
}

class _MuFoodAppState extends State<MuFoodApp> {
  late GoRouter _router;
  DataProvider? _data;
  String? _uid;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = buildRouter(auth);
    auth.addListener(_sync);
    _sync();
  }

  void _sync() {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == _uid) return;
    _data?.dispose();
    _data = uid == null ? null : DataProvider(context.read<DataStore>());
    _uid = uid;
    _router = buildRouter(auth);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_sync);
    _data?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp.router(
      title: 'MU Food Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
    final data = _data;
    if (data != null) {
      app = ChangeNotifierProvider<DataProvider>.value(value: data, child: app);
    }
    return app;
  }
}
