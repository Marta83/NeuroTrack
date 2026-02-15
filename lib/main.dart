import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Evita el error:
    // "A Firebase App named '[DEFAULT]' already exists"
    final bool defaultAppExists =
        Firebase.apps.any((FirebaseApp app) => app.name == '[DEFAULT]');

    if (!defaultAppExists) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase inicializado correctamente.');
    } else {
      debugPrint('Firebase ya estaba inicializado.');
    }
  } catch (e, st) {
    debugPrint('Error al inicializar Firebase: $e');
    debugPrint('$st');
  }

  runApp(const ProviderScope(child: NeuroTrackApp()));
}

class NeuroTrackApp extends ConsumerWidget {
  const NeuroTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NeuroTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      routerConfig: router,
    );
  }
}
