# 🚂 Despliegue de Onyx en Railway

Esta guía te permitirá desplegar Onyx en Railway de manera profesional y escalable.

## 📋 Pre-requisitos

1. Cuenta en [Railway.app](https://railway.app)
2. Railway CLI instalado (opcional pero recomendado):
     ```bash
     npm i -g @railway/cli
     ```
3. Una API key de OpenAI (o proveedor LLM alternativo)

## 🏗️ Arquitectura en Railway

El despliegue constará de los siguientes servicios:

### Servicios Gestionados (Railway Templates)

- **PostgreSQL** - Base de datos principal
- **Redis** - Cache y cola de mensajes

### Servicios Containerizados (Custom Docker)

- **api-server** - Backend API (FastAPI)
- **web-server** - Frontend (Next.js)
- **background-worker** - Workers Celery
- **model-server-inference** - Servidor de embeddings
- **model-server-indexing** - Servidor de embeddings para indexación
- **vespa** - Motor de búsqueda vectorial
- **minio** - Almacenamiento S3-compatible para archivos

## 🚀 Proceso de Despliegue

### PASO 1: Crear Proyecto en Railway

1. Ve a [Railway.app](https://railway.app) y crea un nuevo proyecto
2. Nombra el proyecto: `onyx-production`

### PASO 2: Añadir Servicios Gestionados

#### 2.1 PostgreSQL

```bash
# Via Railway CLI
railway add --database postgres

# O desde la UI: New > Database > PostgreSQL
```

Variables que se crearán automáticamente:

- `DATABASE_URL`
- `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`

#### 2.2 Redis

```bash
# Via Railway CLI
railway add --database redis

# O desde la UI: New > Database > Redis
```

Variables que se crearán automáticamente:

- `REDIS_URL`
- `REDISHOST`, `REDISPORT`, `REDISUSER`, `REDISPASSWORD`

### PASO 3: Configurar Variables de Entorno Compartidas

En Railway, ve a tu proyecto > Variables y añade las siguientes variables compartidas (Shared Variables):

```bash
# AUTH
AUTH_TYPE=disabled
ENCRYPTION_KEY_SECRET=<generar-con-openssl-rand-base64-32>

# LLM Configuration
GEN_AI_MODEL_PROVIDER=openai
GEN_AI_MODEL_VERSION=gpt-4
FAST_GEN_AI_MODEL_VERSION=gpt-3.5-turbo
OPENAI_API_KEY=<tu-api-key>

# Feature Flags
ENABLE_PAID_ENTERPRISE_EDITION_FEATURES=false
USE_LIGHTWEIGHT_BACKGROUND_WORKER=true

# File Storage (MinIO - configuración nativa de Onyx)
FILE_STORE_BACKEND=s3
S3_ENDPOINT_URL=http://${{minio.RAILWAY_PRIVATE_DOMAIN}}:9000
S3_AWS_ACCESS_KEY_ID=minioadmin
S3_AWS_SECRET_ACCESS_KEY=minioadmin
S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket

# Logging
LOG_LEVEL=info
DISABLE_TELEMETRY=true

# Web Domain (Railway te proporcionará uno)
WEB_DOMAIN=${{RAILWAY_PUBLIC_DOMAIN}}
```

### PASO 4: Desplegar Vespa (Motor de Búsqueda)

Vespa es el componente más crítico. Railway necesita un servicio custom:

```bash
# Via CLI
railway service create vespa

# Configurar:
# - Source: Image
# - Image: vespaengine/vespa:8.609.39
# - Port: 8081
```

Variables de entorno para Vespa:

```bash
VESPA_SKIP_UPGRADE_CHECK=true
```

Añadir volumen persistente:

- Mount Path: `/opt/vespa/var`
- Size: 10GB (ajustar según necesidad)

### PASO 5: Desplegar MinIO (Almacenamiento S3)

MinIO proporciona almacenamiento compatible con S3 para archivos de usuarios:

```bash
# Via CLI
railway service create minio

# Configurar:
# - Source: Image
# - Image: minio/minio:RELEASE.2025-07-23T15-54-02Z-cpuv1
# - Port: 9000
```

Variables de entorno para MinIO:

```bash
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_DEFAULT_BUCKETS=onyx-file-store-bucket
```

**Start Command:**

```bash
server /data --console-address ":9001"
```

Añadir volumen persistente:

- Mount Path: `/data`
- Size: 20GB (ajustar según volumen de documentos esperado)

Recursos recomendados:

- RAM: 512MB mínimo
- CPU: 0.5 vCPU

**Importante**: NO habilitar Public Networking (solo acceso interno)

**Opcional**: Si necesitas acceder a la consola de MinIO para debugging:

- Habilita Public Networking temporalmente
- Accede al puerto 9001 (consola web)
- Recuerda deshabilitarlo después

### PASO 6: Desplegar Model Servers

#### 5.1 Inference Model Server

```bash
railway service create model-server-inference
```

Configuración:

- **Source**: GitHub (conecta tu repo)
- **Root Directory**: `backend`
- **Dockerfile Path**: `Dockerfile.model_server`
- **Build Command**: (automático desde Dockerfile)
- **Start Command**: `uvicorn model_server.main:app --host 0.0.0.0 --port 8080`

Variables específicas:

```bash
MIN_THREADS_ML_MODELS=4
LOG_LEVEL=info
PORT=8080
```

Recursos recomendados:

- RAM: 2GB mínimo
- CPU: 2 vCPU

Añadir volumen:

- Mount Path: `/app/.cache/huggingface/`
- Size: 5GB

#### 5.2 Indexing Model Server

```bash
railway service create model-server-indexing
```

Configuración idéntica a inference, pero con estas variables adicionales:

```bash
INDEXING_ONLY=true
VESPA_SEARCHER_THREADS=1
```

### PASO 7: Desplegar API Server (Backend)

```bash
railway service create api-server
```

Configuración:

- **Source**: GitHub
- **Root Directory**: `backend`
- **Dockerfile Path**: `Dockerfile`
- **Start Command**:
     ```bash
     /bin/sh -c "alembic upgrade head && uvicorn onyx.main:app --host 0.0.0.0 --port 8080"
     ```

Variables específicas:

```bash
# Database (referencia al servicio PostgreSQL)
POSTGRES_HOST=${{Postgres.PGHOST}}
POSTGRES_USER=${{Postgres.PGUSER}}
POSTGRES_PASSWORD=${{Postgres.PGPASSWORD}}
POSTGRES_DB=${{Postgres.PGDATABASE}}

# Cache (referencia al servicio Redis)
REDIS_HOST=${{Redis.REDISHOST}}
REDIS_PORT=${{Redis.REDISPORT}}

# Vespa
VESPA_HOST=${{vespa.RAILWAY_PRIVATE_DOMAIN}}

# Model Servers
MODEL_SERVER_HOST=${{model-server-inference.RAILWAY_PRIVATE_DOMAIN}}
INDEXING_MODEL_SERVER_HOST=${{model-server-indexing.RAILWAY_PRIVATE_DOMAIN}}

# MinIO/S3 Configuration
S3_ENDPOINT_URL=http://${{minio.RAILWAY_PRIVATE_DOMAIN}}:9000
S3_AWS_ACCESS_KEY_ID=minioadmin
S3_AWS_SECRET_ACCESS_KEY=minioadmin
S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket

# Port
PORT=8080
```

Recursos recomendados:

- RAM: 1GB mínimo
- CPU: 1 vCPU

**Importante**:

1. Habilitar Public Networking y anotar la URL generada
2. NO necesitas volumen persistente (MinIO maneja el storage)

### PASO 8: Desplegar Background Worker

```bash
railway service create background-worker
```

Configuración:

- **Source**: GitHub
- **Root Directory**: `backend`
- **Dockerfile Path**: `Dockerfile`
- **Start Command**:
     ```bash
     /app/scripts/supervisord_entrypoint.sh
     ```

Variables específicas (mismas que api-server + estas):

```bash
USE_LIGHTWEIGHT_BACKGROUND_WORKER=true
API_SERVER_PROTOCOL=https
API_SERVER_HOST=${{api-server.RAILWAY_PUBLIC_DOMAIN}}
```

Recursos recomendados:

- RAM: 2GB mínimo
- CPU: 2 vCPU

**Importante**: Este servicio NO necesita Public Networking.

### PASO 9: Desplegar Web Server (Frontend)

```bash
railway service create web-server
```

Configuración:

- **Source**: GitHub
- **Root Directory**: `web`
- **Dockerfile Path**: `Dockerfile`
- **Build Args**:
     ```bash
     NEXT_PUBLIC_DISABLE_LOGOUT=false
     ```

Variables específicas:

```bash
# Backend API URL (privada, interna)
INTERNAL_URL=http://${{api-server.RAILWAY_PRIVATE_DOMAIN}}:8080

# Public URL
NEXT_PUBLIC_API_URL=https://${{api-server.RAILWAY_PUBLIC_DOMAIN}}

PORT=3000
```

Recursos recomendados:

- RAM: 512MB mínimo
- CPU: 0.5 vCPU

**Importante**:

1. Habilitar Public Networking
2. Esta será tu URL principal de acceso
3. Railway genera automáticamente SSL/TLS

### PASO 10: Configurar Dependencias entre Servicios

En Railway, configura el orden de inicio:

1. PostgreSQL (primero)
2. Redis (primero)
3. MinIO (segundo)
4. Vespa (segundo)
5. Model Servers (tercero)
6. API Server (cuarto) - depende de DB, Redis, MinIO, Vespa, Models
7. Background Worker (cuarto) - depende de DB, Redis, MinIO, Vespa, Models
8. Web Server (quinto) - depende de API Server

Esto se hace en Railway:

- Selecciona cada servicio
- Ve a Settings > Service Dependencies
- Añade las dependencias necesarias

### PASO 11: Inicializar Base de Datos y MinIO

Una vez desplegado el API Server, las migraciones se ejecutan automáticamente.

**MinIO:** El bucket configurado en `MINIO_DEFAULT_BUCKETS` se crea automáticamente al iniciar MinIO.

Para crear un usuario admin inicial, conecta al servicio:

```bash
# Via Railway CLI
railway run -s api-server python -c "
from onyx.setup import setup_onyx
setup_onyx()
"
```

O usa el API directamente:

```bash
curl -X POST https://<tu-api-server-url>/api/admin/initial-user \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "change-this-password"
  }'
```

## 🔍 Verificación del Despliegue

### 1. Verificar que todos los servicios están running

```bash
railway status
```

### 2. Verificar logs de cada servicio

```bash
railway logs -s api-server
railway logs -s web-server
railway logs -s background-worker
```

### 3. Verificar conectividad

```bash
# Health check API
curl https://<tu-api-server-url>/health

# Health check Web
curl https://<tu-web-server-url>
```

### 4. Verificar Vespa

```bash
railway run -s vespa curl http://localhost:8081/state/v1/health
```

## 📊 Monitoreo

Railway proporciona métricas automáticas:

- CPU usage
- Memory usage
- Network traffic
- Logs en tiempo real

Accede desde: Proyecto > Servicio > Metrics

## 🐛 Troubleshooting

### Servicio no inicia

```bash
# Ver logs
railway logs -s <service-name>

# Ver variables de entorno
railway vars -s <service-name>
```

### Error de conexión a base de datos

- Verifica que las variables POSTGRES\_\* están correctamente referenciadas
- Verifica que el servicio PostgreSQL está running
- Verifica las Service Dependencies

### Model Server OOM (Out of Memory)

- Aumenta la RAM del servicio en Settings > Resources
- Considera usar modelos más ligeros

### Vespa no responde

- Verifica que tiene suficiente memoria (mínimo 2GB)
- Verifica el volumen persistente
- Revisa logs: `railway logs -s vespa`

## 💰 Estimación de Costos

Railway cobra por:

- Recursos (CPU + RAM) por hora
- Network egress
- Storage (volúmenes)

**Estimación mensual** (configuración mínima):

- Hobby Plan: ~$20-30/mes
- Pro Plan recomendado: ~$50-100/mes

Para reducir costos:

- Usa `USE_LIGHTWEIGHT_BACKGROUND_WORKER=true`
- Considera usar embeddings externos (OpenAI) en vez de model servers locales
- Ajusta recursos según uso real

## 🔐 Seguridad

1. **Cambiar AUTH_TYPE a 'basic' o 'oidc'** cuando esté en producción
2. **Generar ENCRYPTION_KEY_SECRET fuerte**:
     ```bash
     openssl rand -base64 32
     ```
3. **Configurar VALID_EMAIL_DOMAINS** para restringir signup
4. **Rotar credenciales** regularmente
5. **Habilitar backups** automáticos de PostgreSQL en Railway

## 🔄 CI/CD

Railway soporta auto-despliegue desde GitHub:

1. Conecta tu repositorio en cada servicio
2. Configura la rama (main/production)
3. Railway detecta cambios y redespliega automáticamente

Para control manual:

- Settings > Deploy Triggers > Manual Deploys Only

## 📈 Escalado

### Horizontal Scaling (múltiples réplicas)

```bash
# Via settings de cada servicio
railway service scale <service-name> replicas=3
```

Servicios que pueden escalar horizontalmente:

- ✅ web-server
- ✅ api-server
- ⚠️ background-worker (con cuidado, puede causar duplicación)
- ❌ vespa (solo vertical)
- ❌ model-servers (considerar usar APIs externas)

### Vertical Scaling (más recursos)

Ajusta en: Service > Settings > Resources

## 🎓 Próximos Pasos

1. ✅ Despliegue básico funcionando
2. 🔐 Configurar autenticación (AUTH_TYPE)
3. 🔗 Configurar conectores (Google Drive, Slack, etc.)
4. 🤖 Configurar LLM alternativo si no usas OpenAI
5. 📊 Configurar monitoring avanzado (Sentry)
6. 🔄 Configurar backups automáticos
7. 🌐 Configurar dominio custom

## 📚 Referencias

- [Railway Docs](https://docs.railway.app)
- [Onyx Docs](https://docs.onyx.app)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**¿Necesitas ayuda?** Abre un issue o contacta al equipo de soporte.
