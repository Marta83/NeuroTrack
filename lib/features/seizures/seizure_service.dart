import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import '../../models/seizure_model.dart';

class SeizureServiceException implements Exception {
  const SeizureServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SeizureService {
  SeizureService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _seizuresCollection =>
      _firestore.collection('seizures');

  CollectionReference<Map<String, dynamic>> get _patientsCollection =>
      _firestore.collection('patients');

  Future<void> createSeizure({
    required String ownerUserId,
    required SeizureModel seizure,
  }) async {
    try {
      await _assertPatientOwnership(
        patientId: seizure.patientId,
        ownerUserId: ownerUserId,
      );
      await _seizuresCollection.doc(seizure.id).set(seizure.toMap());
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        error.message ?? 'No se pudo crear la crisis.',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (_) {
      throw const SeizureServiceException('No se pudo crear la crisis.');
    }
  }

  Future<void> updateSeizure({
    required String ownerUserId,
    required SeizureModel seizure,
  }) async {
    try {
      await _assertPatientOwnership(
        patientId: seizure.patientId,
        ownerUserId: ownerUserId,
      );
      final updatedSeizure = seizure.copyWith(updatedAt: DateTime.now());
      await _seizuresCollection
          .doc(updatedSeizure.id)
          .update(updatedSeizure.toMap());
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        error.message ?? 'No se pudo actualizar la crisis.',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (_) {
      throw const SeizureServiceException('No se pudo actualizar la crisis.');
    }
  }

  Future<void> deleteSeizure({
    required String ownerUserId,
    required String seizureId,
  }) async {
    try {
      final seizureDoc = await _seizuresCollection.doc(seizureId).get();
      if (!seizureDoc.exists) {
        throw const SeizureServiceException('La crisis no existe.');
      }

      final data = seizureDoc.data();
      if (data == null) {
        throw const SeizureServiceException('No se pudo leer la crisis.');
      }

      final patientId = (data['patientId'] as String?) ?? '';
      if (patientId.isEmpty) {
        throw const SeizureServiceException(
            'La crisis no tiene patientId valido.');
      }

      await _assertPatientOwnership(
        patientId: patientId,
        ownerUserId: ownerUserId,
      );
      await _seizuresCollection.doc(seizureId).delete();
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        error.message ?? 'No se pudo eliminar la crisis.',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (_) {
      throw const SeizureServiceException('No se pudo eliminar la crisis.');
    }
  }

  Stream<List<SeizureModel>> streamSeizuresByPatient({
    required String ownerUserId,
    required String patientId,
  }) async* {
    await _assertPatientOwnership(
      patientId: patientId,
      ownerUserId: ownerUserId,
    );

    yield* _seizuresCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final data = doc.data();
        if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
          data['id'] = doc.id;
        }
        return SeizureModel.fromMap(data);
      }).toList(growable: false);
    });
  }

  Stream<List<SeizureModel>> streamSeizuresByPatientFrom({
    required String ownerUserId,
    required String patientId,
    required DateTime from,
  }) async* {
    await _assertPatientOwnership(
      patientId: patientId,
      ownerUserId: ownerUserId,
    );

    yield* _seizuresCollection
        .where('patientId', isEqualTo: patientId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final data = doc.data();
        if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
          data['id'] = doc.id;
        }
        return SeizureModel.fromMap(data);
      }).toList(growable: false);
    });
  }

  Stream<List<SeizureModel>> streamSeizuresByPatientBetween({
    required String ownerUserId,
    required String patientId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async* {
    await _assertPatientOwnership(
      patientId: patientId,
      ownerUserId: ownerUserId,
    );

    yield* _seizuresCollection
        .where('patientId', isEqualTo: patientId)
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive),
        )
        .where(
          'dateTime',
          isLessThan: Timestamp.fromDate(endExclusive),
        )
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final data = doc.data();
        if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
          data['id'] = doc.id;
        }
        return SeizureModel.fromMap(data);
      }).toList(growable: false);
    });
  }

  /// Utilidad SOLO para desarrollo:
  /// genera crisis de prueba en los últimos 6 meses para un paciente.
  Future<void> seedTestSeizuresForPatient(
    String patientId, {
    required String ownerUserId,
    int count = 80,
  }) async {
    if (!kDebugMode) {
      return;
    }
    if (count <= 0) {
      return;
    }

    try {
      if (patientId.trim().isEmpty) {
        throw const SeizureServiceException('patientId inválido.');
      }
      final random = Random();
      await _assertPatientOwnership(
        patientId: patientId,
        ownerUserId: ownerUserId,
      );

      final now = DateTime.now();
      final createdAt = now;
      final start = now.subtract(const Duration(days: 180));
      final occurrences = List<DateTime>.generate(
        count,
        (_) => _randomDateWithRecentBias(random, start: start, end: now),
      )..sort();

      WriteBatch batch = _firestore.batch();
      int ops = 0;

      for (int i = 0; i < occurrences.length; i++) {
        final occurredAt = occurrences[i];
        final data = _generateRandomSeizureData(
          random,
          patientId,
          ownerUserId,
          occurredAt,
          createdAt,
        );
        final doc = _seizuresCollection.doc((data['id'] as String?) ?? '');
        batch.set(doc, data);
        ops += 1;

        if (ops >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          ops = 0;
        }
      }

      if (ops > 0) {
        await batch.commit();
      }
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        '[${error.code}] ${error.message ?? 'No se pudieron generar crisis de prueba.'}',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (error) {
      throw SeizureServiceException(
        'No se pudieron generar crisis de prueba. Detalle: $error',
      );
    }
  }

  /// Utilidad SOLO para desarrollo:
  /// elimina crisis marcadas como `isTestData=true` para un paciente.
  Future<int> deleteSeededTestSeizuresForPatient(
    String patientId, {
    required String ownerUserId,
  }) async {
    if (!kDebugMode) {
      return 0;
    }

    try {
      await _assertPatientOwnership(
        patientId: patientId,
        ownerUserId: ownerUserId,
      );

      int deleted = 0;
      while (true) {
        final snapshot = await _seizuresCollection
            .where('patientId', isEqualTo: patientId)
            .where('isTestData', isEqualTo: true)
            .limit(400)
            .get();

        if (snapshot.docs.isEmpty) {
          break;
        }

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          deleted += 1;
        }
        await batch.commit();
      }

      return deleted;
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        '[${error.code}] ${error.message ?? 'No se pudieron eliminar crisis de prueba.'}',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (error) {
      throw SeizureServiceException(
        'No se pudieron eliminar crisis de prueba. Detalle: $error',
      );
    }
  }

  Future<void> _assertPatientOwnership({
    required String patientId,
    required String ownerUserId,
  }) async {
    final patientDoc = await _patientsCollection.doc(patientId).get();
    if (!patientDoc.exists) {
      throw const SeizureServiceException('El paciente no existe.');
    }

    final data = patientDoc.data();
    final patientOwner = (data?['ownerUserId'] as String?) ?? '';
    if (patientOwner != ownerUserId) {
      throw const SeizureServiceException(
        'No tienes permisos para acceder a este paciente.',
      );
    }
  }

  DateTime _randomDateWithRecentBias(
    Random random, {
    required DateTime start,
    required DateTime end,
  }) {
    final totalSeconds = end.difference(start).inSeconds;
    if (totalSeconds <= 1) {
      return end;
    }

    // Bias hacia fechas más recientes para que la tendencia sea visible.
    final weighted = pow(random.nextDouble(), 1.7).toDouble();
    final secondsFromNow = (weighted * totalSeconds).round();
    return end.subtract(Duration(seconds: secondsFromNow));
  }

  Map<String, dynamic> _generateRandomSeizureData(
    Random random,
    String patientId,
    String ownerUserId,
    DateTime occurredAt,
    DateTime createdAt,
  ) {
    final type = _weightedType(random);
    final intensity = _weightedIntensity(random);
    final durationSeconds = _weightedDurationSeconds(random);
    final recoveryMinutes = _weightedRecoveryMinutes(random);

    final hasRescue = random.nextDouble() < 0.30;
    String? rescueCode;
    if (hasRescue) {
      const rescuePool = <String>[
        'MIDAZOLAM_INTRNASAL',
        'MIDAZOLAM_OROMUCOSAL',
        'DIAZEPAM_RECTAL',
      ];
      rescueCode = rescuePool[random.nextInt(rescuePool.length)];
    }

    final hasTriggers = random.nextDouble() >= 0.50;
    final triggers = hasTriggers ? _randomTriggers(random) : <String>[];

    final seizure = SeizureModel.create(
      patientId: patientId,
      dateTime: occurredAt,
      durationSeconds: durationSeconds,
      durationUnknown: false,
      type: type,
      intensity: intensity,
      postictalRecoveryMinutes: recoveryMinutes,
      triggers: triggers,
      injury: random.nextDouble() < 0.15,
      cyanosis: random.nextDouble() < 0.10,
      emergencyCall: random.nextDouble() < 0.12,
      emergencyVisit: random.nextDouble() < 0.20,
      rescueMedicationCode: rescueCode,
      notes: null,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final map = seizure.toMap();
    map['ownerUserId'] = ownerUserId;
    map['isTestData'] = true;
    map['seededAt'] = Timestamp.fromDate(createdAt);
    return map;
  }

  String _weightedType(Random random) {
    final p = random.nextDouble();
    if (p < 0.45) {
      return 'TONIC_CLONIC';
    }
    if (p < 0.80) {
      return 'FOCAL';
    }
    if (p < 0.93) {
      return 'ABSENCE';
    }
    return 'MYOCLONIC';
  }

  int _weightedIntensity(Random random) {
    final p = random.nextDouble();
    if (p < 0.40) {
      return random.nextBool() ? 1 : 2;
    }
    if (p < 0.75) {
      return 3;
    }
    return random.nextBool() ? 4 : 5;
  }

  int _weightedDurationSeconds(Random random) {
    final p = random.nextDouble();
    if (p < 0.60) {
      return 60 + random.nextInt(61);
    }
    if (p < 0.85) {
      return 20 + random.nextInt(40);
    }
    return 121 + random.nextInt(180);
  }

  int _weightedRecoveryMinutes(Random random) {
    final p = random.nextDouble();
    if (p < 0.65) {
      return 10 + random.nextInt(21);
    }
    if (p < 0.85) {
      return 5 + random.nextInt(5);
    }
    return 31 + random.nextInt(30);
  }

  List<String> _randomTriggers(Random random) {
    const pool = <String>[
      'SLEEP_DEPRIVATION',
      'FEVER',
      'STRESS',
      'MISSED_MEDS',
      'UNKNOWN',
    ];

    final count = random.nextDouble() < 0.7 ? 1 : 2;
    final shuffled = List<String>.from(pool)..shuffle(random);
    return shuffled.take(count).toList(growable: false);
  }
}
