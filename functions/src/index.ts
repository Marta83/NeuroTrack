import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {
  onDocumentCreated,
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

  if (!hasAllKeys(data, required)) {
    return ["Faltan campos en patients."];
  }

  if (!hasOnlyKeys(data, required)) {
    return ["Existen campos no permitidos en patients."];
  }

  const errors: string[] = [];

  if (!isString(data.id) || data.id !== patientId) {
    errors.push("id de paciente invalido.");
  }

  if (!isString(data.ownerUserId) || data.ownerUserId.length === 0) {
    errors.push("ownerUserId invalido.");
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
