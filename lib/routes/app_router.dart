import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/patients/home_screen.dart';
import '../features/patients/patient_history_screen.dart';
import '../features/patients/patient_form_screen.dart';
import '../features/patients/patient_screen.dart';
import '../models/seizure_model.dart';
import '../features/seizures/seizure_form_screen.dart';

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthenticated = authRepository.currentUser != null;
      final bool isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) {
        return '/login';
      }

      if (isAuthenticated && isOnLogin) {
        return '/home';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/patients/new',
        builder: (BuildContext context, GoRouterState state) {
          return const PatientFormScreen.newPatient();
        },
      ),
      GoRoute(
        path: '/patients/:patientId/edit',
        builder: (BuildContext context, GoRouterState state) {
          final patientId = state.pathParameters['patientId'] ?? '';
          return PatientFormScreen.edit(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/patients/:patientId/history',
        builder: (BuildContext context, GoRouterState state) {
          final patientId = state.pathParameters['patientId'] ?? '';
          return PatientHistoryScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/patients/:patientId/seizures/new',
        builder: (BuildContext context, GoRouterState state) {
          final patientId = state.pathParameters['patientId'] ?? '';
          return SeizureFormScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/patients/:patientId/seizures/:seizureId/edit',
        builder: (BuildContext context, GoRouterState state) {
          final patientId = state.pathParameters['patientId'] ?? '';
          final initialSeizure = state.extra is SeizureModel
              ? state.extra as SeizureModel
              : null;
          return SeizureFormScreen(
            patientId: patientId,
            initialSeizure: initialSeizure,
          );
        },
      ),
      GoRoute(
        path: '/patients/:patientId',
        builder: (BuildContext context, GoRouterState state) {
          final patientId = state.pathParameters['patientId'] ?? '';
          return PatientScreen(patientId: patientId);
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
