# Flujo de Contribucion

## Objetivo
Estandarizar como se proponen, implementan y fusionan cambios en el repositorio.

## Estrategia de Ramas
Se usa GitFlow con ramas principales:
- develop: integracion continua de cambios.
- main: releases estables.

Ramas de trabajo:
- feature/<nombre-corto>
- hotfix/<nombre-corto>
- release/<version>

## Reglas de Commits
Se usa Conventional Commits con commits pequenos y atomicos.

Tipos recomendados:
- feat: nueva funcionalidad.
- fix: correccion de bug.
- docs: cambios de documentacion.
- chore: tareas operativas o mantenimiento.
- refactor: cambios internos sin alterar comportamiento.
- test: pruebas nuevas o actualizadas.
- ci: cambios en pipelines.

Formato:
`tipo(scope): descripcion breve en imperativo`

Ejemplos:
- `chore(structure): scaffold infra and services directory layout`
- `docs(architecture): add project execution flow documentation`
- `chore(git): add repository gitignore rules`

## Flujo de Trabajo Recomendado
1. Actualizar develop local.
2. Crear rama feature desde develop.
3. Implementar cambios en lotes atomicos.
4. Hacer commits con convencion establecida.
5. Abrir PR hacia develop con contexto tecnico.
6. Atender feedback de revision.
7. Merge sin reescribir historial de terceros.

## Criterios Minimos para PR
- Titulo formal y claro.
- Descripcion con objetivo, alcance y riesgos.
- Evidencia de validacion (estructura, lint, pruebas, plan).
- Sin secretos ni estados locales versionados.

## Checklist Antes de Merge
- Estructura y nombres consistentes.
- Commits atomicos y mensajes validos.
- Documentacion actualizada si cambia arquitectura o flujo.
- Archivos temporales y de entorno ignorados por git.

## Reglas para Infraestructura
- No aplicar cambios directos en produccion desde ramas personales.
- Separar cambios de infraestructura y aplicacion cuando sea posible.
- Evitar cambios masivos en una sola PR.
- Favorecer modulos pequenos con responsabilidades claras.

## Reglas para Servicios
- Mantener codigo compartido en `services/lambdas/shared`.
- Evitar duplicacion de utilidades entre funciones.
- Estandarizar telemetria en todas las Lambdas.

## Observabilidad y Estandares
- Lambdas en TypeScript deben usar Powertools para logging, metricas y tracing.
- Alarmas y dashboards se gestionan desde IaC.
- Las metricas de negocio deben estar documentadas en la PR.

## Plantilla de PR (Resumen)
- Contexto
- Objetivo
- Cambios incluidos
- Fuera de alcance
- Validacion realizada
- Riesgos y rollback
