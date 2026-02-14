# Cloud Functions Template

Plantilla TypeScript para validar documentos `patients` y `seizures` en backend.

## Uso

1. Desde `functions/`, instalar dependencias: `npm install`
2. Compilar: `npm run build`
3. Desplegar: `npm run deploy`

## Que valida

- `patients/{patientId}`
  - Campos requeridos/permitidos
  - Tipos y rangos
  - `geneSummary` como lista de strings validos
  - Campos inmutables en update (`id`, `ownerUserId`, `createdAt`)
- `seizures/{seizureId}`
  - Campos requeridos/permitidos
  - Tipos y rangos (incluye `intensity` 1-5)
  - Existencia de `patientId`
  - Campos inmutables en update (`id`, `patientId`, `createdAt`)

## Nota

Estos triggers corrigen/eliminan datos invalidos despues de la escritura.
La autorizacion y ownership deben seguir protegidos con Firestore Rules.

## Agregados de investigacion

Se incluyen triggers para estadisticas anonimas:

- `onSeizureCreate`, `onSeizureUpdate`, `onSeizureDelete` sobre `seizures/{seizureId}`
- `onPatientResearchProfileUpdate` sobre `patients/{patientId}` cuando cambia `geneSummary` o `consentForResearch`

Salida:

- `aggregates/global_stats`
- `aggregates/by_gene/items/{geneSymbol}` (equivalente practico en Firestore para el agrupado por gen)

No se persisten `patientId` ni `userId` en los documentos agregados.
