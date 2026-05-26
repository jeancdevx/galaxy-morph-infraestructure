# Roadmap de Implementacion (Quincenal)

## Objetivo
Definir un plan de ejecucion secuencial, con entregables verificables por etapa, responsables por rol y Definition of Done (DoD) para avanzar de forma ordenada hasta una plataforma lista para produccion.

## Supuestos de Planificacion
- Horizonte inicial: 16 quincenas (32 semanas).
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
- Cierre por etapas permitido: baseline en Q4 y cierre completo de telemetria cuando esten activos recursos de Q6-Q8.

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
- Inferencia en modo stub para dev (sin endpoint SageMaker en esta fase).

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

### Q8 (Semanas 15-16) - Auth Layer y API Publica
**Owner principal:** BE

**Entregables:**
- Lambda auth en TypeScript con Powertools (Logger, Tracer, Metrics).
- API Gateway publica: POST /auth/signup, POST /auth/signin, GET /classifications/history.
- Cognito: flujos SRP y USER_PASSWORD_AUTH validados para grupos scientist-user y public-user.
- JWT emitido por Cognito con claim cognito:groups validado end-to-end.

**DoD:**
- Signup, signin y refresh funcionan desde cliente HTTP.
- Claim cognito:groups distingue scientist-user de public-user en el token.
- Lambda desplegada con trazas visibles en X-Ray y logs estructurados en CloudWatch.
- Cobertura minima de pruebas unitarias del handler.

### Q9 (Semanas 17-18) - API Privada e Ingesta
**Owner principal:** BE

**Entregables:**
- Lambda upload en TypeScript: genera N presigned PUT URLs en S3 para subida directa desde cliente.
- Lambda classify en TypeScript: crea job en DynamoDB (status QUEUED) y escribe N mensajes a SQS.
- Cuota por tipo de usuario: public-user <= 10 imagenes/dia via DynamoDB (pk=quota#userId, TTL 24h).
- API Gateway privada con Cognito Authorizer: POST /upload/url, POST /classifications.

**DoD:**
- Presigned PUT URLs generadas y usables directamente desde el cliente.
- Job visible en DynamoDB con status QUEUED tras POST /classifications.
- Mensajes visibles en SQS galaxy-ingestion inmediatamente despues.
- HTTP 429 al undecimo intento diario de un public-user.
- Cobertura minima de pruebas unitarias de ambos handlers.

### Q10 (Semanas 19-20) - Tiempo Real y Results Dispatcher
**Owner principal:** BE + DE

**Entregables:**
- AppSync GraphQL API: mutation notifyClassification y subscription onClassification(clientId).
- Lambda results-dispatcher en TypeScript: MSK Event Source Mapping en topic galaxy.results.
- Dispatcher llama mutation AppSync via HTTP con SigV4 (IAM auth) por cada mensaje Kafka.
- Dispatcher actualiza DynamoDB processedCount++ y marca COMPLETED cuando processedCount == imageCount.

**DoD:**
- Subscription onClassification entrega cada resultado al cliente correcto via WebSocket.
- DynamoDB refleja processedCount actualizado en tiempo real.
- Flujo completo end-to-end validado en dev: POST /classifications -> pipeline Spark -> WebSocket.
- Logs estructurados y trazas X-Ray visibles por cada mensaje procesado.

### Q11 (Semanas 21-22) - Calidad Tecnica y Hardening de Codigo
**Owner principal:** BE + PE + SRE

**Entregables:**

**Lambdas:**
- pnpm workspace raiz con shared package para jsonResponse, tipos comunes y config Powertools base.
- Cada Lambda refactorizada a estructura src/handler.ts + src/services/* + src/lib/* eliminando el god-file index.ts.
- ESLint + Prettier configurados a nivel workspace (config compartida, scripts por Lambda y a nivel raiz).
- Vitest configurado en cada Lambda con cobertura minima 70% en logica de negocio.
- Tests unitarios cubriendo: logica de cuota (ingestion_api), firma SigV4 (results_dispatcher), routing y manejo de errores (auth_api, upload_api, classification_api).

**IAM:**
- Eliminar todos los resources = ["*"] reparables: CloudWatch Logs a log group ARN pattern, SQS a queue ARN especifico, SageMaker InvokeEndpoint a endpoint ARN, Cognito AdminAddUserToGroup a user pool ARN, ECR (excepto ecr:GetAuthorizationToken que genuinamente requiere "*").
- Dividir la politica lambda_runtime en politicas especificas por Lambda: upload_api solo s3:PutObject, ingestion_api sin s3:DeleteObject ni dynamodb:Scan, results_dispatcher sin dynamodb:Scan.
- Eliminar s3:DeleteObject, dynamodb:Scan y sqs:ReceiveMessage de politicas donde el servicio no los necesita.
- Variables IAM sin default = "*": hacer los ARNs requeridos o agregar validacion explicita.
- Anotar con #checkov:skip los resources = ["*"] genuinamente necesarios (ec2:Describe*, ecr:GetAuthorizationToken, logs:* en algunos contextos) con justificacion inline.

**Terraform:**
- Extraer kafka_ui de data_layer a modulo observability_tools independiente.
- Dividir security_groups/security_groups.tf en archivos por servicio (lambda.tf, emr.tf, msk.tf, ecs.tf).
- Descomponer modulo iam: mover politicas de cada servicio a su modulo correspondiente o crear sub-modulos por dominio.
- Dividir api_public.tf y api_private.tf en archivos por responsabilidad (cloudwatch.tf, routes_auth.tf, routes_classifications.tf, deployment.tf).
- Pinear imagen kafka-ui a version especifica (eliminar :latest).

**Checkov:**
- Resolver los fallos remediables: S3 versioning, DynamoDB CMK, SQS CMK, Lambda reserved concurrency, API Gateway access logging.
- Documentar y aplicar #checkov:skip con justificacion para los checks que no aplican al contexto del proyecto.
- Meta: 0 failures sin skip, todos los skips con comentario de razon.
- Integrar checkov en el pipeline de validacion de Terraform junto a fmt/validate/plan.

**DoD:**
- checkov scan: 0 failures; todos los skips documentados con justificacion.
- Todas las Lambdas con tests pasando y cobertura >= 70% en logica de negocio.
- ESLint + Prettier sin errores ni warnings en todos los Lambdas.
- IAM audit: ningun resources = ["*"] sin justificacion documentada.
- terraform fmt/validate sin errores en todos los modulos.
- PR de refactor revisada y aprobada por TL.

### Q12 (Semanas 23-24) - Capa de Presentacion
**Owner principal:** PE

**Entregables:**
- S3 bucket para SPA frontend con bloqueo de acceso publico y OAI.
- CloudFront distribution con dos origenes: S3 SPA y S3 imagenes de galaxias (OAI privado).
- WAF asociado a CloudFront con reglas base: rate limiting y AWS Managed Rules (OWASP Top 10).
- Route53 hosted zone con record apuntando a CloudFront y certificado ACM validado.

**DoD:**
- SPA accesible via dominio CloudFront con HTTPS forzado.
- Imagenes de galaxias servidas via CloudFront (S3 directo bloqueado).
- WAF rechaza requests con patrones de inyeccion en prueba manual.
- Certificado SSL/TLS activo y sin advertencias de browser.

### Q13 (Semanas 25-26) - CI/CD Integral
**Owner principal:** PE + BE + DE + MLE

**Entregables:**
- Pipelines separados para IaC, Lambdas, job EMR y modelo ML.
- Promotion flow dev -> prod con aprobaciones manuales por etapa.
- Estrategia de artefactos versionados: Lambda zip, deps.zip EMR, model.tar.gz SageMaker.

**DoD:**
- Despliegue a dev completamente automatizado desde commit.
- Gates de calidad activos: lint, tests, checkov/tfsec, terraform plan.
- Trazabilidad de release: cada deploy referencia commit y tag de origen.

### Q14 (Semanas 27-28) - Seguridad y Costos
**Owner principal:** SRE

**Entregables:**
- Hardening de IAM (least privilege auditado), cifrado en reposo y en transito, rotacion de secretos.
- Alarmas de presupuesto/costo por dominio (Lambda, SageMaker, MSK, EMR).
- Reglas de retencion de logs y politicas de gobernanza de datos.

**DoD:**
- Informe de seguridad sin hallazgos criticos abiertos.
- Alertas de costo configuradas y validadas con un evento de prueba.
- Cumplimiento de baseline de hardening documentado y aprobado por TL.

### Q15 (Semanas 29-30) - Pruebas No Funcionales
**Owner principal:** QA + SRE

**Entregables:**
- Pruebas E2E por flujos criticos: upload -> clasificacion -> resultado WebSocket.
- Pruebas de carga sostenida y burst en API Gateways, SQS, EMR y SageMaker.
- Ajustes de autoscaling y capacidad basados en resultados de carga.

**DoD:**
- SLOs definidos en Q4 cumplidos bajo carga objetivo.
- Escenarios de falla documentados: endpoint SageMaker down, MSK saturado, Lambda throttled.
- Sin bloqueadores P1/P2 abiertos al cierre de la quincena.

### Q16 (Semanas 31-32) - Go-Live Readiness
**Owner principal:** TL + SRE

**Entregables:**
- Runbooks operativos y playbooks de incidentes para todos los componentes criticos.
- Definicion final de KPIs y SLOs de produccion.
- Plan de salida controlada con rollback documentado por componente.

**DoD:**
- Checklist de go-live 100% completado y firmado por TL y SRE.
- On-call y ownership de soporte definidos con rotacion documentada.
- Aprobacion formal de salida a produccion por TL/SRE.

## Dependencias Criticas
- Q2 depende de Q1 aprobado.
- Q3 y Q4 dependen de Q2.
- Q5 depende de Q3 y Q4.
- Q6 y Q7 dependen de Q5.
- Q8 depende de Q4 (Cognito y IAM base listos). Puede iniciar en paralelo con Q6/Q7.
- Q9 depende de Q8 y Q5 (SQS y DynamoDB listos).
- Q10 depende de Q9, Q6 y Q7 (pipeline Spark y SageMaker endpoint activos).
- Q11 depende de Q10 (deuda tecnica resuelta antes de exponer capa publica).
- Q12 depende de Q11.
- Q13 depende de Q12.
- Q14-Q16 dependen de Q13.

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
- Pipeline de telescopios: ingesta de archivos FITS -> Lambda pre-procesamiento -> SQS -> MSK.
- Tuning avanzado de WAF con reglas personalizadas basadas en trafico real de produccion.
- Frontend SPA (React/Next.js): implementacion del cliente web (fuera de scope de infraestructura).
