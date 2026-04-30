# Roadmap de Implementacion (Quincenal)

## Objetivo
Definir un plan de ejecucion secuencial, con entregables verificables por etapa, responsables por rol y Definition of Done (DoD) para avanzar de forma ordenada hasta una plataforma lista para produccion.

## Supuestos de Planificacion
- Horizonte inicial: 12 quincenas (24 semanas).
- Entornos objetivo: dev y prod.
- Region inicial: us-east-2.
- En esta version se mantiene fuera de alcance el pipeline de telescopios.

## Roles y Ownership
- Tech Lead (TL): decisiones tecnicas, priorizacion y aprobacion arquitectonica.
- Platform Engineer (PE): Terraform, red, IAM, observabilidad base y CI de IaC.
- Backend Engineer (BE): Lambdas, APIs, integraciones y contratos.
- Data Engineer (DE): Spark/EMR, flujo de eventos y rendimiento de procesamiento.
- ML Engineer (MLE): empaquetado de modelo y serving en SageMaker.
- SRE/SecOps (SRE): hardening, alertas, respuesta a incidentes, costo y seguridad.
- QA Engineer (QA): pruebas integracion, e2e, no funcionales y criterios de salida.

## Plan por Quincena

### Q1 (Semanas 1-2) - Foundation y Gobierno
**Owner principal:** TL + PE

**Entregables:**
- Convenciones de repositorio, commits y PR formalizadas.
- Documentacion base del flujo, arquitectura y contribucion.
- Estructura de carpetas final estabilizada.

**DoD:**
- Documentacion aprobada por TL.
- Checklist de PR definido y usado en al menos 1 PR real.
- Estructura de carpetas sin cambios pendientes por naming.

### Q2 (Semanas 3-4) - Bootstrap y Estado Remoto
**Owner principal:** PE

**Entregables:**
- Backend remoto Terraform (S3 + lock table) por entorno.
- Cifrado y convenciones de naming/tagging para estado.
- Pipeline base para validacion de Terraform (fmt/validate/plan).

**DoD:**
- Ningun root module usa state local.
- `terraform init/plan` funcional en dev desde CI.
- Evidencia de locking y cifrado habilitados.

### Q3 (Semanas 5-6) - Red e IAM Base
**Owner principal:** PE

**Entregables:**
- VPC, subredes, route tables y endpoints base.
- Roles/policies IAM de minimo privilegio para servicios core.
- Variables por entorno para red y seguridad.

**DoD:**
- Recursos de red aplicados en dev.
- Politicas IAM revisadas por SRE.
- Documentacion de conectividad y dependencias publicada.

### Q4 (Semanas 7-8) - Observabilidad de Plataforma
**Owner principal:** SRE + PE

**Entregables:**
- Modulos IaC de logs, metricas, alarmas y dashboards.
- Baseline de trazas distribuibles en servicios serverless.
- Convencion de taxonomia de metricas de negocio.

**DoD:**
- Dashboards operativos en dev.
- Alarmas criticas con canal de notificacion.
- Documento de runbook inicial para alertas P1/P2.

### Q5 (Semanas 9-10) - Data Layer y Streaming
**Owner principal:** PE + DE

**Entregables:**
- SQS, MSK, conectividad y componentes asociados.
- DynamoDB para metadata/estado de jobs.
- Contratos de mensajes versionados en servicios/kafka/contracts.

**DoD:**
- Flujo de mensaje de extremo a extremo validado en dev.
- Politica de DLQ/reintentos definida y probada.
- Esquemas de eventos documentados y con tests de contrato.

### Q6 (Semanas 11-12) - Spark/EMR Serverless
**Owner principal:** DE

**Entregables:**
- Job de streaming_classification funcional en EMR Serverless.
- Librerias compartidas de transformacion y utilidades.
- Telemetria de throughput/latencia de pipeline Spark.

**DoD:**
- Job procesando eventos reales en dev.
- SLO preliminar de latencia definido.
- Manejo de errores y reintentos documentado.

### Q7 (Semanas 13-14) - SageMaker Inference
**Owner principal:** MLE

**Entregables:**
- Bundle de modelo y codigo de serving.
- Endpoint realtime con autoscaling base.
- Metricas de inferencia y alarmas de salud de endpoint.

**DoD:**
- Endpoint responde solicitudes validas en dev.
- Versionado de modelo y proceso de rollback documentado.
- Cost baseline de inferencia reportado.

### Q8 (Semanas 15-16) - Lambdas API, Dispatcher y Auth
**Owner principal:** BE

**Entregables:**
- Lambdas de API y results_dispatcher en TypeScript.
- Integracion con AppSync/API Gateway segun flujo definido.
- Uso de Powertools (Logger, Tracer, Metrics) en Lambdas.
- Cognito User Pool, App Clients y flujos de autenticacion integrados con API.

**DoD:**
- Flujo request -> procesamiento -> respuesta realtime validado.
- Logs estructurados y trazas visibles por request.
- Cobertura minima de pruebas unitarias acordada.
- Flujo signup/signin/refresh con JWT validado de extremo a extremo.

### Q9 (Semanas 17-18) - CI/CD Integral
**Owner principal:** PE + BE + DE + MLE

**Entregables:**
- Pipelines separados para IaC y servicios.
- Promotion flow dev -> prod con aprobaciones.
- Estrategia de artefactos versionados (Lambda, Spark, model).

**DoD:**
- Despliegue a dev completamente automatizado.
- Gates de calidad activos (lint/test/scan/plan).
- Evidencia de trazabilidad de release por commit/tag.

### Q10 (Semanas 19-20) - Seguridad y Costos
**Owner principal:** SRE

**Entregables:**
- Hardening de IAM, red, cifrado y secretos.
- Alarmas de presupuesto/costo por dominio.
- Reglas de retencion de logs y gobernanza de datos.

**DoD:**
- Informe de seguridad sin hallazgos criticos abiertos.
- Alertas de costo validadas.
- Cumplimiento de baseline de hardening aprobado.

### Q11 (Semanas 21-22) - Pruebas No Funcionales
**Owner principal:** QA + SRE

**Entregables:**
- Pruebas E2E por flujos criticos.
- Pruebas de carga y resiliencia.
- Ajustes de autoscaling y capacidad.

**DoD:**
- SLOs cumplidos bajo carga objetivo.
- Escenarios de falla y recuperacion documentados.
- Sin bloqueadores P1/P2 abiertos.

### Q12 (Semanas 23-24) - Go-Live Readiness
**Owner principal:** TL + SRE

**Entregables:**
- Runbooks operativos y playbooks de incidentes.
- Definicion de KPIs/SLO finales.
- Plan de salida controlada y seguimiento post-release.

**DoD:**
- Checklist de go-live 100% completado.
- On-call y ownership de soporte definidos.
- Aprobacion formal de salida por TL/SRE.

## Dependencias Criticas
- Q2 depende de Q1 aprobado.
- Q3 y Q4 dependen de Q2.
- Q5 depende de Q3 y Q4.
- Q6 y Q7 dependen de Q5.
- Q8 depende de Q4, Q6 y Q7.
- Q9 depende de Q8.
- Q10-Q12 dependen de Q9.

## Riesgos Principales y Mitigacion
- Riesgo: scope creep temprano.
  - Mitigacion: congelar backlog por quincena y usar change control.
- Riesgo: deuda de observabilidad.
  - Mitigacion: no avanzar de Q4 sin dashboards y alarmas operativas.
- Riesgo: costos de inferencia/streaming.
  - Mitigacion: presupuestos, alarmas y pruebas de carga anticipadas.

## Cadencia de Seguimiento
- Sync tecnico semanal por dominio.
- Revision de avance quincenal contra DoD.
- Retro mensual de calidad tecnica y entrega.

## KPIs de Ejecucion del Roadmap
- % hitos quincenales cerrados en fecha.
- Lead time de cambios por dominio.
- Tasa de rollback por release.
- MTTD y MTTR de incidentes en dev/prod.
- Costo por 1,000 clasificaciones procesadas.

## Backlog Fuera de Fase Actual
- Edge frontend de produccion con CloudFront + Route53.
- Perimetro avanzado con WAF y tuning de reglas por trafico real.
