# GalaxyMorph — Knowledge Base Completa de Arquitectura AWS
**Generado:** 2026-04-16 | **Conversación:** 0a10e8ea-0c89-4719-a7a7-5dc3aa7eef49
**Actualizado:** 2026-04-23 | **Estado:** Decisiones de IaC/región/scope alineadas al repositorio actual

---

## 1. ¿Qué es GalaxyMorph?

**Proyecto de tesis doctoral** de clasificación morfológica automática de galaxias usando Deep Learning (CNN con PyTorch), entrenado sobre el esquema Hubble-de Vaucouleurs con datos de Galaxy Zoo 2.

### Las 5 Clases de Clasificación

| Clase | Símbolo | Descripción | Consenso GZ2 |
|-------|---------|-------------|--------------|
| Elliptical | ⭕ | Sin disco, forma suave, población estelar vieja | Inicia con `E` |
| Spiral | 🌀 | Disco frontal, brazos espirales sin barra | Inicia con `S` |
| Barred_Spiral | 🌀 | Espiral con barra de estrellas en el núcleo | Inicia con `SB` |
| Edge_on | 🛸 | Galaxia de disco vista de canto/perfil | Inicia con `Se` |
| Irregular_Merger | 💥 | Forma asimétrica/caótica por colisiones | Marcado con `(i)`, `(m)`, `(d)` |

### Contexto Astronómico y Escala Real

- Los telescopios espaciales fotografían **160 millones de galaxias nuevas por mes**
- **250,000 científicos** trabajan en la clasificación manual
- El sistema debe poder procesar todo ese volumen automáticamente
- **No existe un frontend/backend/API previos** — todo se construye desde cero
- Solo se mantiene: la idea del flujo, el modelo CNN entrenado

---

## 2. Arquitectura Original (Docker On-Premise) — Solo para Referencia

Existía antes de la migración a AWS. **NO se replica al pie de la letra.**

```
Frontend → API REST
  POST /upload/url → Presigned URLs → Subida a Cloudflare R2
  POST /classifications → Publica a Kafka topic galaxy.ingestion
  WebSocket → escucha events: classification:result, classification:error

Kafka: 3 brokers, 3 réplicas, 3 particiones por broker
Spark Master + 3 Spark Workers (modelo CNN cargado en cada worker)
Spark consume galaxy.ingestion → clasifica → publica a galaxy.results
API suscrita a galaxy.results → reenvía por WebSocket al cliente
```

### Mensaje de ingesta original (kafka topic: galaxy.ingestion)
```json
{
  "jobId": "6556ebcb-0b29-49c7-b58f-1027431d5c9f",
  "imageKey": "galaxies/bf2f0abb-97a7-4cd2-bc1b-08dc5853ae38/galaxia_espiral.jpg",
  "clientId": "insomnia-client-001",
  "timestamp": "2026-04-07T12:50:43.142Z"
}
```

### Mensaje de resultado original (kafka topic: galaxy.results)
```json
{
  "jobId": "b9f8ab57-e6f9-466a-9708-95e71b1df764",
  "clientId": "insomnia-client-001",
  "imageKey": "galaxies/bf2f0abb-97a7-4cd2-bc1b-08dc5853ae38/galaxia_espiral.jpg",
  "status": "SUCCESS",
  "classification": {
    "predictedClass": "Barred_Spiral",
    "confidence": 0.754791,
    "probabilities": {
      "Elliptical": 0.002293,
      "Spiral": 0.242865,
      "Barred_Spiral": 0.754791,
      "Edge_on": 0.000051,
      "Irregular_Merger": 0.000001
    }
  }
}
```

---

## 3. Escala del Sistema AWS

| Parámetro | Valor |
|-----------|-------|
| Usuarios simultáneos máx. | 250,000 científicos |
| Imágenes por usuario (máx.) | 3,000 |
| Carga máxima teórica (burst extremo) | 750,000,000 mensajes |
| Volumen mensual (telescopios) | 160,000,000 imágenes |
| Throughput promedio | ~62 imágenes/segundo |
| Throughput peak estimado | ~620 imágenes/segundo |
| Tamaño de mensaje Kafka | ~200-400 bytes (solo metadata/imageKey, NO la imagen) |
| Throughput real en MSK | ~25 KB/s promedio, ~250 KB/s peak |

**IMPORTANTE:** Las imágenes viven en S3. Por Kafka solo fluyen referencias (imageKey). El throughput en Kafka es pequeño.

---

## 4. Arquitectura AWS — Decisiones Tomadas y Justificaciones

### 4.1 Capa de Presentación
| Servicio | Rol | Decisión |
|----------|-----|----------|
| Route53 | DNS | ✅ Estándar |
| CloudFront | CDN + cache de assets estáticos + entrega de imágenes S3 | ✅ |
| WAF | Firewall de capa 7 | ✅ Protege CloudFront |
| S3 (frontend) | Sirve la SPA (React/Next.js) | ✅ |

### 4.2 Autenticación
| Servicio | Rol | Decisión |
|----------|-----|----------|
| Cognito User Pool | Auth, JWT tokens | ✅ Token source: Authorization header |
| API Gateway Cognito Authorizer | Valida JWT en endpoints privados | ✅ |

### 4.3 API Layer
**Dos API Gateways:**

| API Gateway | Tipo | Endpoints | Auth |
|-------------|------|-----------|------|
| Pública | REST | POST /auth/signup, POST /auth/signin | Sin auth |
| Privada (VPC) | REST | POST /upload/url, POST /classifications | Cognito JWT |

**AppSync API** (para WebSocket/subscripciones en tiempo real):
- Auth: Cognito User Pool (mismo que API REST)
- Sin límite documentado de conexiones concurrentes (escala a millones)
- Subscription filters nativos por clientId → no necesita DynamoDB connections table

**¿Por qué AppSync y no API Gateway WebSocket?**
- API GW WebSocket tiene límite de ~10K-50K conexiones concurrentes por cuenta/región, incluso con quota increase no llega a 250K
- AppSync escala a millones de conexiones concurrentes
- AppSync tiene filtrado nativo de subscripciones: `onClassification(clientId: "scientist-001")` solo entrega al científico correcto automáticamente
- Elimina la necesidad de tabla DynamoDB `connections` (clientId → connectionId mapping)

### 4.4 Capa de Ingesta y Buffer

**Flujo:**
```
POST /classifications
   → Lambda (validación + DynamoDB job record)
   → SQS Standard Queue: galaxy-submissions
   → MSK Connect (SQS Source Connector, 2-100 workers auto-scaling)
   → MSK Serverless — Topic: galaxy.ingestion
```

**¿Por qué SQS → MSK Connect y NO Lambda → MSK directo?**

A escala de 250K usuarios con 160M imágenes/mes, Lambda como Kafka Producer falla porque:
1. Lambda concurrencia limitada (~1K default, ~10K max con quota increase) → con 250K usuarios necesitas 25K+ ejecuciones simultáneas
2. Lambda abre una nueva conexión TCP al broker MSK POR INVOCACIÓN → explosión de conexiones a los brokers
3. Cold starts masivos bajo burst: cientos de Lambdas arrancando simultáneamente hacen TLS handshake con MSK
4. Lambda no es un Kafka Producer persistente, no reutiliza conexiones

MSK Connect SQS Source Connector:
- Mantiene conexiones TCP persistentes y reutilizadas (como un Kafka Producer real)
- No tiene límites de concurrencia como Lambda
- Long Polling 20ms → near real-time (no es "polling lento")
- Auto-scaling de workers según profundidad de la cola SQS
- 100 workers × 50K msgs/s = 5M msgs/min si el burst es extremo

**Configuración SQS:**
- Tipo: Standard Queue (no FIFO, el orden por imagen no es crítico)
- Retention: 14 días
- Visibility Timeout: 30 segundos
- DLQ: galaxy-submissions-dlq (3 intentos fallidos → DLQ)

**¿Por qué NO el flujo original Lambda → EventBridge → SQS → Lambda → S3 → MSK Connect S3 Source?**
- MSK Connect S3 Source Connector está diseñado para ETL masivo de datos históricos, NO para mensajería en tiempo real
- Tiene polling por archivos (segundos a minutos de latencia)
- 6 saltos innecesarios vs 4 con SQS directo
- El S3 Source Connector agrega latencia impredecible

### 4.5 MSK (Kafka)

**Decisión: MSK Serverless** (no Provisioned)

| Parámetro | Valor |
|-----------|-------|
| Tipo | MSK Serverless |
| Auth | IAM (única opción en Serverless, compatible con Lambda + EMR) |
| Particiones | 50 por topic (no 3 — con 3 solo hay 3 tasks paralelas en Spark) |
| Replication Factor | 3 (gestionado por AWS en Serverless) |
| Retención galaxy.ingestion | 7 días |
| Retención galaxy.results | 3 días |

**Topics:**
- `galaxy.ingestion`: 50 particiones, RF=3
- `galaxy.results`: 50 particiones, RF=3

**¿Por qué MSK Serverless?**
- Los mensajes son metadata (~400 bytes), no imágenes → throughput real ~250 KB/s peak vs límite 200 MB/s del Serverless = **10x margen**
- Carga variable (no 24/7 constante) → pago por uso, no por brokers siempre activos
- Cero gestión de brokers, storage, instancias → AWS lo gestiona todo
- IAM auth compatible con todos los servicios (MSK Connect, EMR, Lambda)

**¿Cuándo elegirías Provisioned + Express Brokers?**
Si los mensajes Kafka fueran las imágenes mismas (MB cada uno) forzando throughput de GB/s. No es el caso aquí.

**Sobre Express vs Standard Brokers (solo si fuera Provisioned):**
- Express: 3x throughput, storage gestionado por AWS, escala 20x más rápido → moderno, recomendado
- Standard: control total de storage y config, pero más ops overhead

### 4.6 Procesamiento Distribuido

**Decisión: EMR Serverless con Spark Structured Streaming**

| Parámetro | Valor |
|-----------|-------|
| Tipo | EMR Serverless |
| Framework | Apache Spark Structured Streaming |
| Pre-initialized capacity | 20 workers (warm pool para eliminar cold start) |
| Max capacity | 500 workers (auto-scale en burst) |
| Micro-batch interval | 5 segundos |
| Checkpoint | S3 (s3://galaxy-morph-checkpoints/) |

**EMR Serverless vs EMR on EC2:**
- EMR on EC2: cluster siempre corriendo, siempre pagando (EC2 instances), mejor para carga 24/7 constante
- EMR Serverless: auto-scaling 0→500 workers, pago por vCPU-hora solo cuando procesa, ideal para carga variable/bursts, pre-initialized capacity reduce cold start a ~10 segundos

**Spark como Consumer Y Producer de Kafka (sin Lambda intermedio):**
```python
# Spark LEE de galaxy.ingestion
spark.readStream.format("kafka") \
    .option("subscribe", "galaxy.ingestion") ...

# Spark ESCRIBE en galaxy.results (DIRECTO, sin Lambda)
results.writeStream.format("kafka") \
    .option("topic", "galaxy.results") \
    .option("checkpointLocation", "s3://galaxy-morph-checkpoints/results-writer/") ...
```
El checkpoint en S3 garantiza at-least-once processing si EMR se reinicia.

### 4.7 ML Inference — SageMaker

**Decisión: SageMaker Real-Time Endpoint**

| Parámetro | Valor |
|-----------|-------|
| Tipo | Real-Time Endpoint |
| Instancias | ml.g4dn.xlarge (GPU) |
| Min instancias | 2 (alta disponibilidad) |
| Max instancias | 50 |
| Auto Scaling metric | SageMakerVariantInvocationsPerInstance |
| Auto Scaling target | 1,000 invocaciones/minuto por instancia |
| Scale-out cooldown | 60s |
| Scale-in cooldown | 300s |

**¿Por qué SageMaker como endpoint independiente (patrón empresarial)?**
1. Separación de responsabilidades: EMR hace procesamiento, SageMaker hace inferencia
2. Ciclo de vida del modelo independiente: actualiza CNN sin tocar EMR
3. Model Registry: versionado, A/B testing, rollback
4. Model Monitor: detección de data drift en producción
5. Auto-scaling de inferencia independiente del cluster Spark

**Cómo Spark llama a SageMaker:**
```python
def process_partition(partition_rows):
    s3_client = boto3.client("s3")
    sm_client = boto3.client("sagemaker-runtime")
    for row in partition_rows:
        image_bytes = s3_client.get_object(Bucket=BUCKET, Key=row.imageKey)["Body"].read()
        result = sm_client.invoke_endpoint(
            EndpointName="galaxy-morph-classifier-v1",
            ContentType="application/x-image",
            Body=image_bytes
        )
        # yield resultado con clasificación + probabilidades
```

**Tipos de SageMaker endpoints y cuándo usar cada uno:**
| Tipo | Latencia | Costo | Usar cuando |
|------|----------|-------|-------------|
| Real-Time | ~50-200ms | Instancias activas | ✅ Streaming imagen por imagen |
| Serverless | ~200ms-2s (cold) | Por invocación | Bajo volumen intermitente |
| Async Inference | Minutos | Por invocación | Imágenes muy grandes |
| Batch Transform | Horas | Por instancia-hora | Grandes batches offline |

### 4.8 Entrega en Tiempo Real

**Flujo:**
```
MSK galaxy.results
  └─► Lambda (MSK Event Source Mapping — trigger automático)
        └─► HTTP POST a AppSync (GraphQL Mutation, auth IAM SigV4)
              └─► AppSync filtra por clientId
                    └─► WebSocket → Científico correcto
```

**Lambda Results Dispatcher:**
- Trigger: MSK Event Source Mapping en topic galaxy.results
- Llama a AppSync via HTTP con mutation `notifyClassification`
- Actualiza DynamoDB tabla `jobs`: processedCount++
- Si processedCount == imageCount → status: COMPLETED

**AppSync GraphQL Schema:**
```graphql
type ClassificationProbabilities {
  Elliptical: Float
  Spiral: Float
  Barred_Spiral: Float
  Edge_on: Float
  Irregular_Merger: Float
}

type ClassificationResult {
  predictedClass: String!
  confidence: Float!
  probabilities: ClassificationProbabilities!
}

type ClassificationEvent {
  jobId: String!
  clientId: String!
  imageKey: String!
  imageUrl: String!         # URL CloudFront para mostrar la imagen en el browser
  status: String!           # SUCCESS | ERROR
  processedAt: String!
  classification: ClassificationResult
  errorMessage: String      # solo si status=ERROR
}

type Mutation {
  notifyClassification(input: ClassificationEventInput!): ClassificationEvent
}

type Subscription {
  onClassification(clientId: String!): ClassificationEvent
    @aws_subscribe(mutations: ["notifyClassification"])
}
```

**Clave de entendimiento:** Lambda ES el cliente que llama AppSync. La dirección es Lambda → AppSync. AppSync → Científico. NO al revés.

### 4.9 Persistencia — DynamoDB

**Tabla: `jobs`**
```json
{
  "pk": "job#6556ebcb-...",
  "sk": "metadata",
  "clientId": "scientist-001",
  "status": "QUEUED | PROCESSING | COMPLETED | FAILED",
  "imageCount": 3000,
  "processedCount": 1523,
  "createdAt": "2026-04-16T15:00:00Z",
  "updatedAt": "2026-04-16T15:01:30Z",
  "ttl": 1744588800
}
```

**¿Por qué NO hay tabla `connections` (clientId → connectionId)?**
Con AppSync no necesitas mapear connectionIds. AppSync gestiona el routing de subscripciones internamente. Los subscription filters nativos hacen el trabajo.

### 4.10 Storage — S3

| Bucket | Contenido | Acceso |
|--------|-----------|--------|
| galaxy-morph-images | Imágenes de galaxias (galaxies/{userId}/{uuid}.jpg) | Privado, via CloudFront OAI |
| galaxy-morph-raw | Datos de telescopios en formato FITS (pipeline futuro) | Privado |
| galaxy-morph-models | Artefactos del modelo CNN PyTorch | Privado (EMR + SageMaker) |
| galaxy-morph-checkpoints | Checkpoints de Spark Streaming | Privado (EMR) |
| galaxy-morph-frontend | SPA estática (React/Next.js) | Público via CloudFront |

**imageUrl que recibe el científico:**
```
imageKey:  "galaxies/scientist-001/uuid1.jpg"
imageUrl:  "https://d1234.cloudfront.net/galaxies/scientist-001/uuid1.jpg"
```
La imagen se renderiza con `<img src={imageUrl}>` en el browser. La imagen NO viaja por WebSocket.

### 4.11 VPC y Red

**VPC: 10.0.0.0/16**

| Subnet | AZ | CIDR | Contiene |
|--------|-----|------|----------|
| Public A | us-east-2a | 10.0.1.0/24 | NAT Gateway |
| Public B | us-east-2b | 10.0.2.0/24 | NAT Gateway (HA) |
| Private A | us-east-2a | 10.0.11.0/24 | MSK, Lambda, EMR |
| Private B | us-east-2b | 10.0.12.0/24 | MSK, Lambda, EMR |

**Security Groups:**
| SG | Permite entrada desde | Puerto |
|----|----------------------|--------|
| sg-msk | sg-lambda, sg-emr, sg-msk-connect | 9098 (IAM/TLS en Serverless) |
| sg-lambda-private | API Gateway (managed) | — |
| sg-emr | sg-emr (inter-worker) | Todos |
| sg-sagemaker-endpoint | sg-emr | 443 (HTTPS) |

**VPC Endpoints (tráfico privado, sin salir a internet):**
- S3 Gateway Endpoint (gratis)
- DynamoDB Gateway Endpoint (gratis)
- SageMaker Runtime Interface Endpoint
- SQS Interface Endpoint

**Nota de estado:** Security Groups y VPC Endpoints siguen siendo requerimientos de arquitectura. En el repositorio ya se inició implementación de red base en desarrollo (módulo VPC), pero estos componentes aún no están cerrados en producción.

---

## 5. Flujo End-to-End Completo

### Fase 0: El científico abre la app
- Login: POST /auth/signin → Cognito → JWT
- UI carga (SPA desde CloudFront + S3)
- **WebSocket NO se abre aún** (se abre al hacer click en "Procesar")

### Fase 1: Subida de imágenes
```
Científico arrastra N imágenes → click "Procesar"
  │
  ├─► Conectar AppSync WebSocket + esperar subscription ACK (~300ms)
  │   subscription { onClassification(clientId: "scientist-001") { ... } }
  │
  ├─► (En paralelo) POST /upload/url → Lambda → Presigned PUT URLs × N
  │
  └─► PUT a S3 presigned URLs × N (en lotes de 10 en paralelo)
       → "Subiendo: 1247/3000 imágenes" (barra de progreso)
```

### Fase 2: Inicio de clasificación
```
[Todas las imágenes subidas + WebSocket ACK confirmado]
  │
  └─► POST /classifications
        Body: { clientId: "scientist-001", images: [{key: "galaxies/..."}, ...] }
        │
        ├─ Lambda crea job en DynamoDB (status: QUEUED)
        └─ Lambda escribe N mensajes a SQS: { jobId, imageKey, clientId, timestamp }
        → Responde 202 Accepted: { jobId }
```

### Fase 3: Pipeline de ingesta (asíncrono)
```
SQS (galaxy-submissions)
  → MSK Connect SQS Source Connector (Long Polling 20ms)
  → MSK Serverless Topic: galaxy.ingestion (50 particiones)
```

### Fase 4: Procesamiento distribuido
```
EMR Serverless Spark (micro-batch 5s, 50 tasks paralelas)
  ← Lee de galaxy.ingestion
  Por cada imagen:
    1. S3.getObject(imageKey) → image_bytes
    2. SageMaker.invoke_endpoint(image_bytes) → { predictedClass, confidence, probabilities }
    3. Construye resultado JSON con imageUrl (CloudFront URL)
  → Escribe a galaxy.results (DIRECTO, sin Lambda, nativo Kafka Producer)
```

### Fase 5: Entrega en tiempo real
```
MSK galaxy.results
  → Lambda Results Dispatcher (MSK Event Source Mapping)
    → HTTP POST a AppSync mutation notifyClassification({ clientId, ... })
    → DynamoDB: processedCount++
  → AppSync filtra: entrega solo a scientist-001
  → WebSocket del científico recibe imagen por imagen:
    {
      jobId, imageKey, imageUrl,
      classification: {
        predictedClass: "Barred_Spiral",
        confidence: 0.754791,
        probabilities: { Elliptical, Spiral, Barred_Spiral, Edge_on, Irregular_Merger }
      }
    }
```

### Fase 6: Completado
```
processedCount == imageCount
  → Lambda actualiza DynamoDB: status COMPLETED
  → AppSync entrega último mensaje
  → Frontend cierra WebSocket
  → UI muestra resumen: distribución de clases, opción exportar CSV
```

---

## 6. UX/UI Flow — Estados de la Pantalla

```
Estado 1: Drag & Drop Zone
  → Usuario arrastra N imágenes
  → [Botón: 🚀 Procesar imágenes]

Estado 2: Subiendo (POST /upload/url + PUT to S3)
  → Loading bar: "Subiendo imagen 1247/3000..."
  → En background: WebSocket conectando

Estado 3: En cola
  → "✅ 3,000 imágenes subidas"
  → "⏳ Preparando procesamiento distribuido..."
  → "Job ID: 6556ebcb-..."

Estado 4: Clasificando (llegan resultados vía WebSocket)
  → "Clasificadas: 47/3,000 ████░░░░ 1.6%"
  → Grid de tarjetas apareciendo de izq a der:
    [🖼 img] [🖼 img] [🖼 img] ...
    🌀Spiral  ⭕Elliptical  🛸Edge_on
    82.3%       91.7%        88.2%

Estado 5: Completado
  → "✅ 3,000/3,000 clasificadas"
  → Resumen: Spiral 29.7%, Barred_Spiral 24.8%, ...
  → [📥 Descargar CSV] [🔄 Clasificar más]
```

**Timing del WebSocket:**
- Abre: con el click en "Procesar" (en paralelo con subida de imágenes)
- Espera ACK de AppSync antes de enviar POST /classifications
- Cierra: cuando processedCount == imageCount o después de 10min de inactividad

---

## 7. Diagrama de Servicios AWS Completo

```
INTERNET
   │
Route53 (DNS)
   │
CloudFront (CDN + WAF)
   ├─► S3 (SPA frontend)
   └─► S3 (imágenes de galaxias) [OAI privado]

Cognito User Pool (Auth, JWT)

API GW Pública (REST)
  ├─ POST /auth/signup → Lambda Auth → Cognito
  └─ POST /auth/signin → Lambda Auth → Cognito

API GW Privada REST (VPC, Cognito Authorizer)
  ├─ POST /upload/url → Lambda Upload → S3 Presigned URLs
  └─ POST /classifications → Lambda Classifications → DynamoDB + SQS

AppSync API (WebSocket, Cognito Auth)
  └─ Subscription: onClassification(clientId)

VPC (10.0.0.0/16)
  │
  SQS Standard Queue: galaxy-submissions (+ DLQ)
  │
  MSK Connect (SQS Source Connector, 2-100 workers)
  │
  MSK Serverless
    ├─ Topic: galaxy.ingestion (50 particiones, RF=3)
    └─ Topic: galaxy.results (50 particiones, RF=3)
  │                                           │
  EMR Serverless (Spark Streaming)     Lambda Results Dispatcher
  ├─ Reads from galaxy.ingestion       ├─ MSK Event Source Mapping
  ├─ S3.getObject(imageKey)            ├─ Llama AppSync mutation
  ├─ SageMaker.invoke_endpoint()       └─ DynamoDB processedCount++
  └─ Writes to galaxy.results
        │
        SageMaker Real-Time Endpoint
        (CNN PyTorch, ml.g4dn.xlarge, Auto Scaling 2-50)

DynamoDB
  └─ Tabla: jobs (status, processedCount, imageCount)

S3 Buckets
  ├─ galaxy-morph-images (galaxies/{userId}/{uuid}.jpg)
  ├─ galaxy-morph-models (CNN artifacts)
  ├─ galaxy-morph-checkpoints (Spark streaming checkpoints)
  ├─ galaxy-morph-raw (datos de telescopios - pipeline futuro)
  └─ galaxy-morph-frontend (SPA estática)
```

---

## 8. Decisiones de Implementación (actualizadas)

| # | Decisión | Opciones | Status |
|---|----------|----------|--------|
| 1 | IaC | Terraform vs AWS CDK | ✅ Terraform elegido |
| 2 | SageMaker instance | ml.g4dn.xlarge (GPU) vs ml.c5.2xlarge (CPU) | ✅ GPU (ml.g4dn.xlarge) |
| 3 | Región AWS | us-east-1 o us-west-2 | ✅ us-east-2 |
| 4 | Pipeline de telescopios | ¿Incluir en scope inicial? FITS files → Lambda pre-proc → SQS → MSK | ✅ Fuera de scope inicial |
| 5 | Frontend framework | React, Next.js, u otro | ⏳ Pendiente |

---

## 9. Decisiones Tomadas y Fijas (NO reabrir)

| Decisión | Elegida | Descartada | Razón |
|----------|---------|------------|-------|
| Kafka delivery WebSocket | AppSync Subscriptions | API GW WebSocket | 250K conexiones, filtrado nativo |
| Buffer de ingesta | SQS | EventBridge+SQS+Lambda+S3+MSK S3 Connector | Simplicidad, durabilidad |
| Conector SQS→MSK | MSK Connect SQS Source | Lambda MSK Producer | Escala 250K, conexiones persistentes |
| MSK tipo | Serverless | Provisioned | Metadata liviana, carga variable |
| ML inference | SageMaker Real-Time Endpoint | Modelo embebido en EMR | Patrón empresarial, ciclo de vida independiente |
| Procesamiento | EMR Serverless | EMR on EC2 | Carga variable, auto-scaling, costo |
| Spark→Kafka | Nativo spark-sql-kafka | Lambda intermediario | Spark es producer nativo |
| DynamoDB connections table | ❌ Eliminada | ✅ No necesaria | AppSync gestiona subscriptions internamente |
| WebSocket timing | Al hacer click en "Procesar" | Al cargar la app | No desperdiciar conexiones |

---

## 10. Cosas que NO existen aún y deben construirse desde cero

- Frontend (SPA)
- Backend / API (Lambdas)
- Infraestructura AWS completa (la implementación está en progreso por fases)
- Repositorio de infraestructura ya inicializado con estructura de Terraform, bootstrap de estado remoto y raíz de entornos dev/prod

El modelo CNN PyTorch sí existe (resultado de la tesis), debe ser empaquetado como SageMaker Model.

---

## 11. Notas Técnicas Importantes

### MSK Connect SQS Source Connector
- Plugin disponible nativamente en MSK Connect (Confluent SQS Source Connector)
- Long Polling configurable (mínimo 20ms de latencia)
- Auto-scaling basado en CloudWatch metric: `SQS.ApproximateNumberOfMessages`

### EMR Serverless y MSK Serverless — Conectividad
- Ambos deben estar en la misma VPC
- MSK Serverless auth: IAM (no SCRAM)
- EMR necesita rol IAM con permisos: `kafka-cluster:*` en el cluster MSK
- Spark usa `software.amazon.msk.auth.iam.IAMLoginModule` para auth

### AppSync → Lambda (Results Dispatcher)
- Lambda necesita rol IAM con permiso: `appsync:GraphQL` en el ARN del AppSync API
- Lambda firma requests a AppSync con SigV4 (IAM auth)
- El `clientId` en la mutation es el filtro que AppSync usa para routing

### SageMaker packaging para PyTorch
```python
# inference.py requerido
def model_fn(model_dir):     # carga el modelo desde model_dir
def input_fn(data, content_type):   # image bytes → tensor
def predict_fn(input_data, model):  # tensor → 5 probabilidades
def output_fn(prediction, accept):  # → JSON con predictedClass + probabilities
```
