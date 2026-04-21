# Flujo de Ejecucion del Proyecto

## Objetivo
Este documento describe el flujo completo del proyecto Galaxy Morph en su fase inicial y de crecimiento, con foco en infraestructura como codigo, servicios distribuidos y observabilidad fuerte.

## Alcance de Esta Fase
- Definicion de estructura de repositorio.
- Preparacion de modulos de Terraform por dominio.
- Preparacion de carpetas de servicios (Lambda, EMR, Kafka tools, SageMaker serving).
- Base de observabilidad con CloudWatch y X-Ray.
- Exclusion explicita del pipeline de telescopios en esta fase.

## Arquitectura de Alto Nivel
1. El frontend solicita procesamiento de clasificacion.
2. La API registra y encola trabajo de clasificacion.
3. SQS entrega eventos al pipeline de datos via MSK Connect.
4. Spark en EMR Serverless consume eventos, procesa y genera resultados.
5. SageMaker endpoint ejecuta inferencia cuando aplica.
6. Resultados se publican en canales realtime para el cliente.
7. CloudWatch y X-Ray capturan telemetria operacional y de negocio.

## Servicios a Usar
### Infraestructura y Plataforma
- AWS VPC, subredes, routing y endpoints privados.
- IAM con permisos por servicio y minimo privilegio.
- S3 para almacenamiento de artefactos, datos y frontend.
- DynamoDB para metadata y estado de jobs.
- SQS para desacople y buffering.
- MSK/MSK Connect para streaming de mensajes.
- EMR Serverless para procesamiento distribuido.
- SageMaker endpoint para inferencia en tiempo real.
- AppSync y API Gateway para integracion de clientes.
- CloudWatch y X-Ray para observabilidad.

### Codigo de Servicios
- Lambda APIs y dispatcher de resultados.
- Jobs Spark de clasificacion en streaming.
- Paquete de inferencia de SageMaker.
- Contratos y herramientas de Kafka para pruebas y diagnostico.

## Etapas del Proyecto
1. Foundation: estructura de repositorio, convenciones y baseline de IaC.
2. Bootstrap: estado remoto de Terraform, locking y permisos de despliegue.
3. Network and Security: red, IAM, endpoints y politicas base.
4. Data and Streaming: SQS, MSK, conectores y persistencia.
5. Compute and Inference: EMR Serverless y SageMaker.
6. API and Realtime: API Gateway, AppSync y Lambdas.
7. Observability: logs, metricas, alarmas, dashboards y trazas.
8. Hardening and Readiness: pruebas, tuning y preparacion para produccion.

## Responsabilidades por Capa
### Terraform (iac)
- Provisiona y versiona recursos cloud.
- Define configuracion de seguridad, red y escalado.
- No compila ni empaqueta codigo de negocio en apply.

### Services (services)
- Implementa la logica de negocio distribuida.
- Publica artefactos versionados para despliegue.
- Emite telemetria estandarizada.

### Observability
- Terraform crea infraestructura de monitoreo.
- Servicios emiten logs/metricas/traces con estandares comunes.

## Decision de Lenguajes
- Lambdas: TypeScript con Powertools for AWS Lambda (TypeScript).
- Spark: PySpark para jobs de procesamiento.
- SageMaker serving: Python para handler de inferencia.

## Convenciones Operativas
- Entornos separados: dev y prod.
- Commits atomicos bajo Conventional Commits.
- Estrategia GitFlow para ramas y merges.
- Cambios de infraestructura validados antes de merge.

## Fuera de Alcance Actual
- Pipeline de telescopios.
- Automatizaciones avanzadas de despliegue multi-cuenta.
- Optimización de costos de segunda fase.
