# Galaxy Morph Infrastructure

Repositorio de infraestructura y servicios para Galaxy Morph, una plataforma distribuida para clasificacion de morfologia de galaxias.

## Estado
Fase actual: foundation y preparacion de entorno.

Incluye:
- Estructura de carpetas para IaC, servicios y pruebas.
- Separacion de entornos `dev` y `prod`.
- Base para observabilidad fuerte (CloudWatch y X-Ray).

No incluye aun:
- Provisionamiento Terraform funcional completo.
- Implementacion de logica de negocio en servicios.
- Pipeline de telescopios (fuera de alcance en esta fase).

## Estructura General
- [iac/](iac): infraestructura como codigo con Terraform.
- [services/](services): codigo de servicios (Lambdas, Spark/EMR, SageMaker, Kafka tools).
- [docs/](docs): documentacion de arquitectura, flujo y contribucion.
- [scripts/](scripts): utilidades de desarrollo y release.
- [tests/](tests): pruebas de integracion y end-to-end.

## Documentacion Clave
- [docs/galaxy_morph_architecture_knowledge.md](docs/galaxy_morph_architecture_knowledge.md): base de decisiones y contexto tecnico.
- [docs/project_execution_flow.md](docs/project_execution_flow.md): flujo completo del proyecto, etapas y servicios.
- [docs/contribution_workflow.md](docs/contribution_workflow.md): convenciones de contribucion, commits y PR.

## Convenciones de Trabajo
- Estrategia de ramas: GitFlow.
- Commits: Conventional Commits, atomicos y con scope.
- IaC y codigo de servicios se mantienen separados.

## Stack Tecnico Definido
- Lambdas: TypeScript + Powertools for AWS Lambda.
- Spark: PySpark para procesamiento en EMR Serverless.
- Serving de modelo: Python para SageMaker.

## Region y Entornos
- Region objetivo inicial: `us-east-2`.
- Entornos activos: `dev` y `prod`.

## Siguiente Paso
Implementar archivos base de Terraform en bootstrap, entornos y modulos con validaciones de CI.
