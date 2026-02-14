import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final userId = authRepository.currentUser?.uid;
    final isAuthLoading = ref.watch(authControllerProvider).isLoading;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final patientsAsync = ref.watch(patientsByOwnerProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: <Widget>[
          IconButton(
            onPressed: isAuthLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(
              child: Text('No hay pacientes registrados.'),
            );
          }

          return ListView.separated(
            itemCount: patients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final patient = patients[index];
              final title = patient.alias.isNotEmpty
                  ? patient.alias
                  : 'Paciente ${patient.id.substring(0, 8)}';

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  'Genes: ${patient.geneSummary.isEmpty ? 'Sin datos' : patient.geneSummary.join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/patients/${patient.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return Center(child: Text('Error: $error'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patients/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('Anadir paciente'),
      ),
    );
  }
}
