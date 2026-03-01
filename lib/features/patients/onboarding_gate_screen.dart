import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class OnboardingGateScreen extends ConsumerStatefulWidget {
  const OnboardingGateScreen({super.key});

  @override
  ConsumerState<OnboardingGateScreen> createState() =>
      _OnboardingGateScreenState();
}

class _OnboardingGateScreenState extends ConsumerState<OnboardingGateScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolve();
    });
  }

  Future<void> _resolve() async {
    setState(() => _error = null);

    try {
      final auth = ref.read(authRepositoryProvider);
      final uid = auth.currentUser?.uid;
      if (uid == null) {
        if (!mounted) {
          return;
        }
        context.go('/login');
        return;
      }

      final repo = ref.read(patientRepositoryProvider);
      final hasPatients = await repo.userHasPatients(uid);

      if (!mounted) {
        return;
      }

      if (!hasPatients) {
        context.go('/patients/new?first=true');
        return;
      }

      final firstPatientId = await repo.getFirstPatientId(uid);
      if (!mounted) {
        return;
      }

      if (firstPatientId == null || firstPatientId.trim().isEmpty) {
        context.go('/patients/new?first=true');
        return;
      }

      context.go('/patients/$firstPatientId');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'No se pudo comprobar el acceso.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _resolve,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
