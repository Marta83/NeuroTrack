import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";

initializeApp();
const db = getFirestore();

type Plain = Record<string, unknown>;

function isString(value: unknown): value is string {
  return typeof value === "string";
}

function isInt(value: unknown): value is number {
  return Number.isInteger(value);
}

function isTimestamp(value: unknown): boolean {
  return value instanceof Timestamp;
}

function timestampToMillis(value: unknown): number | null {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }
  return null;
}

function hasOnlyKeys(data: Plain, allowed: string[]): boolean {
  const keys = Object.keys(data);
  return keys.every((key) => allowed.includes(key));
}

function hasAllKeys(data: Plain, required: string[]): boolean {
  return required.every((key) => Object.prototype.hasOwnProperty.call(data, key));
}

function validateGeneSummary(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return ["geneSummary debe ser una lista."];
  }

  if (value.length > 100) {
    return ["geneSummary excede 100 elementos."];
  }

  const pattern = /^[A-Z0-9-]+$/;
  for (const gene of value) {
    if (!isString(gene)) {
      return ["Cada gen en geneSummary debe ser string."];
    }
    const normalized = gene.trim().toUpperCase();
    if (!normalized || normalized.length > 20 || !pattern.test(normalized)) {
      return ["geneSummary contiene genes invalidos."];
    }
  }

  return [];
}

function validatePatientData(data: Plain, patientId: string): string[] {
  const required = [
    "id",
    "ownerUserId",
    "birthYear",
    "sex",
    "country",
    "geneSummary",
    "consentForResearch",
    "consentAcceptedAt",
    "consentVersion",
    "createdAt",
    "updatedAt",
  ];
  const allowed = [...required, "alias"];

  if (!hasAllKeys(data, required)) {
    return ["Faltan campos en patients."];
  }

  if (!hasOnlyKeys(data, allowed)) {
    return ["Existen campos no permitidos en patients."];
  }

  const errors: string[] = [];

  if (!isString(data.id) || data.id !== patientId) {
    errors.push("id de paciente invalido.");
  }

  if (!isString(data.ownerUserId) || data.ownerUserId.length === 0) {
    errors.push("ownerUserId invalido.");
  }

  if (data.alias != null) {
    if (!isString(data.alias) || data.alias.length > 80) {
      errors.push("alias invalido.");
    }
  }

  if (!isInt(data.birthYear) || data.birthYear < 1900 || data.birthYear > 2100) {
    errors.push("birthYear fuera de rango.");
  }

  if (!isString(data.sex) || data.sex.trim().length === 0 || data.sex.length > 30) {
    errors.push("sex invalido.");
  }

  if (!isString(data.country) || data.country.trim().length === 0 || data.country.length > 100) {
    errors.push("country invalido.");
  }

  if (typeof data.consentForResearch !== "boolean") {
    errors.push("consentForResearch invalido.");
  }

  if (!isTimestamp(data.consentAcceptedAt)) {
    errors.push("consentAcceptedAt debe ser timestamp.");
  }

  if (
    !isString(data.consentVersion) ||
    data.consentVersion.trim().length === 0 ||
    data.consentVersion.length > 40
  ) {
    errors.push("consentVersion invalido.");
  }

  if (!isTimestamp(data.createdAt) || !isTimestamp(data.updatedAt)) {
    errors.push("createdAt/updatedAt deben ser timestamp.");
  }

  errors.push(...validateGeneSummary(data.geneSummary));
  return errors;
}

function validateSeizureData(data: Plain, seizureId: string): string[] {
  const required = [
    "id",
    "patientId",
    "dateTime",
    "durationSeconds",
    "type",
    "intensity",
    "medicationUsed",
    "notes",
    "createdAt",
    "updatedAt",
  ];

  if (!hasAllKeys(data, required)) {
    return ["Faltan campos en seizures."];
  }

  if (!hasOnlyKeys(data, required)) {
    return ["Existen campos no permitidos en seizures."];
  }

  const errors: string[] = [];

  if (!isString(data.id) || data.id !== seizureId) {
    errors.push("id de seizure invalido.");
  }

  if (!isString(data.patientId) || data.patientId.trim().length === 0) {
    errors.push("patientId invalido.");
  }

  if (!isTimestamp(data.dateTime)) {
    errors.push("dateTime debe ser timestamp.");
  }

  if (!isInt(data.durationSeconds) || data.durationSeconds < 0 || data.durationSeconds > 86400) {
    errors.push("durationSeconds fuera de rango.");
  }

  if (!isString(data.type) || data.type.trim().length === 0 || data.type.length > 50) {
    errors.push("type invalido.");
  }

  if (!isInt(data.intensity) || data.intensity < 1 || data.intensity > 5) {
    errors.push("intensity fuera de rango (1-5).");
  }

  if (!isString(data.medicationUsed) || data.medicationUsed.length > 500) {
    errors.push("medicationUsed invalido.");
  }

  if (!isString(data.notes) || data.notes.length > 2000) {
    errors.push("notes invalido.");
  }

  if (!isTimestamp(data.createdAt) || !isTimestamp(data.updatedAt)) {
    errors.push("createdAt/updatedAt deben ser timestamp.");
  }

  return errors;
}

export const validatePatientOnCreate = onDocumentCreated(
  "patients/{patientId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      return;
    }

    const data = snap.data() as Plain;
    const patientId = event.params.patientId;
    const errors = validatePatientData(data, patientId);

    if (errors.length > 0) {
      logger.error("Invalid patient create", { patientId, errors });
      await snap.ref.delete();
    }
  },
);

export const validatePatientOnUpdate = onDocumentUpdated(
  "patients/{patientId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) {
      return;
    }

    const patientId = event.params.patientId;
    const beforeData = before.data() as Plain;
    const afterData = after.data() as Plain;

    const errors = validatePatientData(afterData, patientId);

    const beforeCreatedAtMs = timestampToMillis(beforeData.createdAt);
    const afterCreatedAtMs = timestampToMillis(afterData.createdAt);

    const immutableChanged =
      beforeData.id !== afterData.id ||
      beforeData.ownerUserId !== afterData.ownerUserId ||
      beforeCreatedAtMs == null ||
      afterCreatedAtMs == null ||
      beforeCreatedAtMs !== afterCreatedAtMs;

    if (errors.length > 0 || immutableChanged) {
      logger.error("Invalid patient update, reverting", {
        patientId,
        errors,
        immutableChanged,
      });
      await after.ref.set(beforeData);
    }
  },
);

export const validateSeizureOnCreate = onDocumentCreated(
  "seizures/{seizureId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      return;
    }

    const data = snap.data() as Plain;
    const seizureId = event.params.seizureId;
    const errors = validateSeizureData(data, seizureId);

    if (errors.length > 0) {
      logger.error("Invalid seizure create", { seizureId, errors });
      await snap.ref.delete();
      return;
    }

    const patientId = data.patientId;
    if (!isString(patientId)) {
      await snap.ref.delete();
      return;
    }

    const patientDoc = await db.collection("patients").doc(patientId).get();
    if (!patientDoc.exists) {
      logger.error("Invalid seizure: patient not found", { seizureId, patientId });
      await snap.ref.delete();
    }
  },
);

export const validateSeizureOnUpdate = onDocumentUpdated(
  "seizures/{seizureId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) {
      return;
    }

    const seizureId = event.params.seizureId;
    const beforeData = before.data() as Plain;
    const afterData = after.data() as Plain;

    const errors = validateSeizureData(afterData, seizureId);

    const beforeCreatedAtMs = timestampToMillis(beforeData.createdAt);
    const afterCreatedAtMs = timestampToMillis(afterData.createdAt);

    const immutableChanged =
      beforeData.id !== afterData.id ||
      beforeData.patientId !== afterData.patientId ||
      beforeCreatedAtMs == null ||
      afterCreatedAtMs == null ||
      beforeCreatedAtMs !== afterCreatedAtMs;

    if (errors.length > 0 || immutableChanged) {
      logger.error("Invalid seizure update, reverting", {
        seizureId,
        errors,
        immutableChanged,
      });
      await after.ref.set(beforeData);
    }
  },
);

type PatientResearchProfile = {
  genes: string[];
};

type Accumulator = {
  totalCrises: number;
  sumDuration: number;
  sumIntensity: number;
  patients: Set<string>;
};

function asNonEmptyString(value: unknown): string | null {
  if (!isString(value)) {
    return null;
  }
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function asNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function normalizeGenes(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const normalized = new Set<string>();
  for (const gene of value) {
    if (!isString(gene)) {
      continue;
    }
    const cleaned = gene.trim().toUpperCase();
    if (cleaned.length > 0) {
      normalized.add(cleaned);
    }
  }
  return Array.from(normalized);
}

function chunkArray<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

function createAccumulator(): Accumulator {
  return {
    totalCrises: 0,
    sumDuration: 0,
    sumIntensity: 0,
    patients: new Set<string>(),
  };
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

function toStats(acc: Accumulator): Plain {
  const avgDuration = acc.totalCrises === 0 ? 0 : round2(acc.sumDuration / acc.totalCrises);
  const avgIntensity = acc.totalCrises === 0 ? 0 : round2(acc.sumIntensity / acc.totalCrises);

  return {
    totalCrises: acc.totalCrises,
    avgDuration,
    avgIntensity,
    totalPatients: acc.patients.size,
    updatedAt: Timestamp.now(),
  };
}

async function recomputeResearchAggregates(trigger: string): Promise<void> {
  logger.info("Recomputing research aggregates", { trigger });

  const consentedPatientsSnapshot = await db
    .collection("patients")
    .where("consentForResearch", "==", true)
    .get();

  const patientProfiles = new Map<string, PatientResearchProfile>();
  for (const doc of consentedPatientsSnapshot.docs) {
    const data = doc.data() as Plain;
    const genes = normalizeGenes(data.geneSummary);
    patientProfiles.set(doc.id, { genes });
  }

  const globalAcc = createAccumulator();
  const byGeneAcc = new Map<string, Accumulator>();

  const patientIds = Array.from(patientProfiles.keys());
  const patientIdChunks = chunkArray(patientIds, 30);

  for (const idChunk of patientIdChunks) {
    const seizuresSnapshot = await db
      .collection("seizures")
      .where("patientId", "in", idChunk)
      .get();

    for (const seizureDoc of seizuresSnapshot.docs) {
      const seizure = seizureDoc.data() as Plain;
      const patientId = asNonEmptyString(seizure.patientId);
      if (patientId == null) {
        continue;
      }

      const profile = patientProfiles.get(patientId);
      if (profile == null) {
        continue;
      }

      const duration = asNumber(seizure.durationSeconds);
      const intensity = asNumber(seizure.intensity);
      if (
        duration == null ||
        intensity == null ||
        duration <= 0 ||
        duration > 86400 ||
        intensity < 1 ||
        intensity > 5
      ) {
        continue;
      }

      globalAcc.totalCrises += 1;
      globalAcc.sumDuration += duration;
      globalAcc.sumIntensity += intensity;
      globalAcc.patients.add(patientId);

      for (const gene of profile.genes) {
        const geneAcc = byGeneAcc.get(gene) ?? createAccumulator();
        geneAcc.totalCrises += 1;
        geneAcc.sumDuration += duration;
        geneAcc.sumIntensity += intensity;
        geneAcc.patients.add(patientId);
        byGeneAcc.set(gene, geneAcc);
      }
    }
  }

  const batch = db.batch();

  const globalStatsRef = db.collection("aggregates").doc("global_stats");
  batch.set(globalStatsRef, toStats(globalAcc));

  const byGeneCollection = db.collection("aggregates").doc("by_gene").collection("items");
  const existingByGeneSnapshot = await byGeneCollection.get();
  const newGeneKeys = new Set<string>(byGeneAcc.keys());

  for (const doc of existingByGeneSnapshot.docs) {
    if (!newGeneKeys.has(doc.id)) {
      batch.delete(doc.ref);
    }
  }

  for (const [gene, acc] of byGeneAcc.entries()) {
    const geneRef = byGeneCollection.doc(gene);
    batch.set(geneRef, toStats(acc));
  }

  await batch.commit();
  logger.info("Research aggregates updated", {
    totalCrises: globalAcc.totalCrises,
    totalPatients: globalAcc.patients.size,
    genes: byGeneAcc.size,
  });
}

async function onSeizureChange(
  beforeData: Plain | null,
  afterData: Plain | null,
  eventType: "create" | "update" | "delete",
): Promise<void> {
  const rawPatientId = (afterData?.patientId ?? beforeData?.patientId) as unknown;
  const patientId = asNonEmptyString(rawPatientId);

  logger.info("Seizure change detected", {
    eventType,
    patientId,
  });

  if (patientId == null) {
    logger.warn("Skipping aggregate recompute: missing patientId", { eventType });
    return;
  }

  try {
    const patientDoc = await db.collection("patients").doc(patientId).get();
    const consentForResearch = Boolean((patientDoc.data() as Plain | undefined)?.consentForResearch);
    logger.info("Patient consent state for seizure change", {
      patientId,
      consentForResearch,
    });
  } catch (error) {
    logger.error("Failed reading patient before aggregate recompute", {
      patientId,
      error,
    });
  }

  await recomputeResearchAggregates(`seizure_${eventType}`);
}

export const onSeizureCreate = onDocumentCreated(
  "seizures/{seizureId}",
  async (event) => {
    try {
      const afterData = (event.data?.data() as Plain | undefined) ?? null;
      await onSeizureChange(null, afterData, "create");
    } catch (error) {
      logger.error("onSeizureCreate failed", {
        seizureId: event.params.seizureId,
        error,
      });
      throw error;
    }
  },
);

export const onSeizureUpdate = onDocumentUpdated(
  "seizures/{seizureId}",
  async (event) => {
    try {
      const beforeData = (event.data?.before.data() as Plain | undefined) ?? null;
      const afterData = (event.data?.after.data() as Plain | undefined) ?? null;
      await onSeizureChange(beforeData, afterData, "update");
    } catch (error) {
      logger.error("onSeizureUpdate failed", {
        seizureId: event.params.seizureId,
        error,
      });
      throw error;
    }
  },
);

export const onSeizureDelete = onDocumentDeleted(
  "seizures/{seizureId}",
  async (event) => {
    try {
      const beforeData = (event.data?.data() as Plain | undefined) ?? null;
      await onSeizureChange(beforeData, null, "delete");
    } catch (error) {
      logger.error("onSeizureDelete failed", {
        seizureId: event.params.seizureId,
        error,
      });
      throw error;
    }
  },
);

export const onPatientResearchProfileUpdate = onDocumentUpdated(
  "patients/{patientId}",
  async (event) => {
    const before = event.data?.before.data() as Plain | undefined;
    const after = event.data?.after.data() as Plain | undefined;
    if (!before || !after) {
      return;
    }

    const beforeGenes = normalizeGenes(before.geneSummary);
    const afterGenes = normalizeGenes(after.geneSummary);
    const beforeConsent = Boolean(before.consentForResearch);
    const afterConsent = Boolean(after.consentForResearch);

    const genesChanged =
      beforeGenes.length !== afterGenes.length ||
      beforeGenes.some((gene) => !afterGenes.includes(gene));
    const consentChanged = beforeConsent !== afterConsent;

    if (!genesChanged && !consentChanged) {
      return;
    }

    try {
      logger.info("Patient research profile changed, recomputing aggregates", {
        patientId: event.params.patientId,
        genesChanged,
        consentChanged,
      });
      await recomputeResearchAggregates("patient_profile_update");
    } catch (error) {
      logger.error("onPatientResearchProfileUpdate failed", {
        patientId: event.params.patientId,
        error,
      });
      throw error;
    }
  },
);
