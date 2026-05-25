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
- [docs/implementation_roadmap.md](docs/implementation_roadmap.md): roadmap quincenal con owners, entregables y Definition of Done por etapa.

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
Ejecutar la Q2 del roadmap: bootstrap de estado remoto Terraform, bloqueo de estado y validacion en CI.

docker pull bridgecrew/checkov:3
docker run --rm -v ./iac:/tf --workdir /tf bridgecrew/checkov:3 --directory /tf -o junitxml --output-file-path results.xml

## pasos para ejecutar
fase 1:
en tfvars:
enable_msk_connect_connector = false
sagemaker_enable_endpoint    = false

cd iac/environments/dev
terraform apply -auto-approve

fase 2:
# 1. Descargar Kafka y la librería IAM auth de AWS
wget -q https://archive.apache.org/dist/kafka/3.5.1/kafka_2.13-3.5.1.tgz && \
tar -xzf kafka_2.13-3.5.1.tgz && \
wget -q https://github.com/aws/aws-msk-iam-auth/releases/download/v2.3.0/aws-msk-iam-auth-2.3.0-all.jar \
  -P kafka_2.13-3.5.1/libs/

# 2. Configurar autenticación IAM
cat > client.properties << 'EOF'
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
EOF

# 3. Definir el broker
export BS="boot-5mw8mtoy.c2.kafka-serverless.us-east-2.amazonaws.com:9098"

# 4. Crear los topics
kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --create --if-not-exists \
  --bootstrap-server $BS \
  --command-config client.properties \
  --replication-factor 2 \
  --partitions 24 \
  --topic galaxy.ingestion

kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --create --if-not-exists \
  --bootstrap-server $BS \
  --command-config client.properties \
  --replication-factor 2 \
  --partitions 24 \
  --topic galaxy.results

# 5. Verificar que ambos topics existen
kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --list \
  --bootstrap-server $BS \
  --command-config client.properties

fase 3:
en tfvars:
enable_msk_connect_connector = true   # ← cambiar
sagemaker_enable_endpoint    = false  # ← sigue en false

terraform apply -auto-approve

fase 4:
# 4a. Modelo SageMaker (necesita best.pth en el directorio)
cd services/ml/model_bundle
make upload

# 4b. Job EMR (pipeline.py + deps)
cd services/emr/jobs/streaming_classification
make upload

fase 5:
en tfvars:
enable_msk_connect_connector = true   # ya estaba
sagemaker_enable_endpoint    = true   # ← cambiar

cd iac/environments/dev
terraform apply

# Esperar ~5 min a que el endpoint pase a InService
aws sagemaker describe-endpoint \
  --endpoint-name galaxy-morph-dev-galaxy-classifier \
  --query 'EndpointStatus' --output text \
  --profile default --region us-east-2

fase 6:
INFERENCE_MODE=sagemaker \
  SAGEMAKER_ENDPOINT_NAME="galaxy-morph-dev-galaxy-classifier" \
  ./services/emr/jobs/streaming_classification/scripts/submit_dev_job.sh


## AppSync WebSocket

Generar el header para la URL del WebSocket (reemplazar `<ID_TOKEN>` con el token de Cognito):

```bash
node -e "
const token = '<ID_TOKEN>';
const host = 'fumt26qrmfahvnnnla44rcctd4.appsync-api.us-east-2.amazonaws.com';
console.log(encodeURIComponent(Buffer.from(JSON.stringify({Authorization: token, host})).toString('base64')));
"
```

Mensaje `start` para registrar la suscripcion (reemplazar `<ID_TOKEN>` y `<CLIENT_ID>`):

```json
{
  "id": "sub1",
  "type": "start",
  "payload": {
    "data": "{\"query\":\"subscription OnClassification($clientId: ID!) { onClassification(clientId: $clientId) { jobId clientId imageKey status classification { predictedClass confidence probabilities } errorMessage } }\",\"variables\":{\"clientId\":\"<CLIENT_ID>\"}}",
    "extensions": {
      "authorization": {
        "Authorization": "<ID_TOKEN>",
        "host": "fumt26qrmfahvnnnla44rcctd4.appsync-api.us-east-2.amazonaws.com"
      }
    }
  }
}
```