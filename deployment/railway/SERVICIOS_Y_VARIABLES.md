# 🚂 CONFIGURACIÓN DE SERVICIOS EN RAILWAY

Esta guía detalla **cada servicio**, sus **variables de entorno**, **puertos configurables** y **Dockerfiles** necesarios para desplegar Onyx en Railway.

---

## 📋 ÍNDICE DE SERVICIOS

1. [PostgreSQL (Manejado)](#1-postgresql-manejado)
2. [Redis (Manejado)](#2-redis-manejado)
3. [MinIO](#3-minio)
4. [Vespa](#4-vespa)
5. [Inference Model Server](#5-inference-model-server)
6. [Indexing Model Server](#6-indexing-model-server)
7. [API Server](#7-api-server)
8. [Background Worker](#8-background-worker)
9. [Web Server](#9-web-server)

---

## 1. PostgreSQL (Manejado)

### 📦 Tipo de Servicio

**Railway Managed Database** - No requiere Dockerfile

### ⚙️ Variables de Entorno

```bash
# Railway las proporciona automáticamente:
PGHOST=${{Postgres.PGHOST}}
PGPORT=${{Postgres.PGPORT}}
PGDATABASE=${{Postgres.PGDATABASE}}
PGUSER=${{Postgres.PGUSER}}
PGPASSWORD=${{Postgres.PGPASSWORD}}
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

### 🔌 Puerto

- **Puerto por defecto**: `5432` (Railway lo maneja internamente)
- **No configurable** - Railway asigna automáticamente

### 🐳 Dockerfile

**No aplica** - Servicio manejado por Railway

### 📝 Notas

- Railway proporciona PostgreSQL 15.x
- Extensiones requeridas se instalan via migraciones de Alembic:
     - `pg_trgm` (búsqueda de texto)
     - `pgcrypto` (encriptación)

---

## 2. Redis (Manejado)

### 📦 Tipo de Servicio

**Railway Managed Database** - No requiere Dockerfile

### ⚙️ Variables de Entorno

```bash
# Railway las proporciona automáticamente:
REDIS_URL=${{Redis.REDIS_URL}}
REDIS_HOST=${{Redis.RAILWAY_PRIVATE_DOMAIN}}
REDIS_PORT=${{Redis.PORT}}
```

### 🔌 Puerto

- **Puerto por defecto**: `6379` (Railway lo maneja internamente)
- **No configurable** - Railway asigna automáticamente

### 🐳 Dockerfile

**No aplica** - Servicio manejado por Railway

### 📝 Notas

- Redis se usa para caché y coordinación de Celery
- Configurado en modo **efímero** (`--save "" --appendonly no`)

---

## 3. MinIO

### 📦 Tipo de Servicio

**Docker Image**: `minio/minio:RELEASE.2025-07-23T15-54-02Z-cpuv1`

### ⚙️ Variables de Entorno

```bash
# Credenciales de MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin_secure_password_123

# Bucket por defecto
MINIO_DEFAULT_BUCKETS=onyx-file-store-bucket

# Puerto interno (Railway lo maneja)
PORT=9000
```

### 🔌 Puertos

- **Puerto API**: `9000` (principal, para S3 API)
- **Puerto Console**: `9001` (UI administrativa)
- **Configurable via**: Variable `PORT` en Railway (por defecto `9000`)

### 🐳 Dockerfile

**No requiere Dockerfile custom** - Usa imagen pública de Docker Hub

### 🚀 Comando de Inicio

```bash
server /data --console-address ":9001"
```

### 📝 Configuración en Railway

```bash
# Build Settings
Type: Docker Image
Image: minio/minio:RELEASE.2025-07-23T15-54-02Z-cpuv1

# Deploy Settings
Start Command: server /data --console-address ":9001"

# Volume
Mount Path: /data
Size: 20GB
```

---

## 4. Vespa

### 📦 Tipo de Servicio

**Docker Image**: `vespaengine/vespa:8.609.39`

### ⚙️ Variables de Entorno

```bash
# Deshabilitar check de actualización
VESPA_SKIP_UPGRADE_CHECK=true
```

### 🔌 Puertos

- **Puerto Config**: `19071` (configuración y deploy)
- **Puerto Query**: `8081` (consultas y búsqueda)
- **No configurables** - Vespa usa estos puertos internamente

### 🐳 Dockerfile

**No requiere Dockerfile custom** - Usa imagen pública de Docker Hub

### 🚀 Comando de Inicio

Vespa usa su **entrypoint por defecto** (no se requiere comando custom)

### 📝 Configuración en Railway

```bash
# Build Settings
Type: Docker Image
Image: vespaengine/vespa:8.609.39

# Deploy Settings
Start Command: (dejar vacío - usa entrypoint por defecto)

# Volume
Mount Path: /opt/vespa/var
Size: 20GB
```

### ⚠️ Importante

- El nombre del servicio **NO debe tener guiones bajos** (`_`)
- Usar `vespa` o `index`, NO `vespa_index`

---

## 5. Inference Model Server

### 📦 Tipo de Servicio

**Build from Dockerfile**

### 📂 Ubicación del Dockerfile

```
backend/Dockerfile.model_server
```

### ⚙️ Variables de Entorno

```bash
# Puerto del servidor (configurable)
PORT=9000

# Modo de operación
INDEXING_ONLY=False

# Modelo de embeddings (opcional, se detecta automáticamente)
MODEL_NAME=intfloat/e5-base-v2

# Caché de modelos
HF_HOME=/app/.cache/huggingface
```

### 🔌 Puerto

- **Puerto por defecto**: `9000`
- **Configurable via**: Variable `PORT` en Railway
- **Railway lo expone automáticamente** en el dominio privado

### 🐳 Build Configuration

**⚠️ IMPORTANTE: Configuración correcta del Build Context**

En Railway, debes configurar el servicio así:

#### Opción 1: Via Railway UI

1. **Settings → Build**
     - Builder: **Dockerfile**
     - Dockerfile Path: **Dockerfile.model_server** ← (NO incluir `backend/`)
     - Root Directory: **backend** ← (CRÍTICO: debe ser `backend`)

2. **Settings → Deploy**
     - Start Command: `uvicorn model_server.main:app --host 0.0.0.0 --port $PORT`

#### Opción 2: Via Railway CLI

```bash
# Crear servicio (desde la raíz del proyecto)
railway service create inference-model-server

# Configurar build
railway service update \
  --root-directory backend \
  --dockerfile-path Dockerfile.model_server
```

### 📝 Configuración de Variables

```bash
railway variables set \
  PORT=9000 \
  INDEXING_ONLY=False \
  MODEL_NAME=intfloat/e5-base-v2
```

### ⚠️ Troubleshooting

**Error: `/model_server: not found`**

Esto ocurre cuando el Root Directory NO está configurado como `backend`. Railway necesita:

- **Root Directory = `backend`** (el contexto de build)
- **Dockerfile Path = `Dockerfile.model_server`** (relativo al Root Directory)

Si ves este error, verifica en **Settings → Build** que Root Directory sea exactamente `backend`.

### 🗂️ Volumen (Opcional)

- **Mount Path**: `/app/.cache/huggingface`
- **Propósito**: Cachear modelos descargados para reducir tiempo de inicio

---

## 6. Indexing Model Server

### 📦 Tipo de Servicio

**Build from Dockerfile**

### 📂 Ubicación del Dockerfile

```
backend/Dockerfile.model_server
```

### ⚙️ Variables de Entorno

```bash
# Puerto del servidor (configurable)
PORT=9000

# Modo de operación (IMPORTANTE: debe ser True)
INDEXING_ONLY=True

# Modelo de embeddings (opcional)
DOCUMENT_ENCODER_MODEL=intfloat/e5-base-v2

# Caché de modelos
HF_HOME=/app/.cache/huggingface
```

### 🔌 Puerto

- **Puerto por defecto**: `9000`
- **Configurable via**: Variable `PORT` en Railway
- **Nota**: Puede usar el mismo puerto que Inference porque son servicios separados

### 🐳 Build Configuration

**⚠️ IMPORTANTE: Configuración correcta del Build Context**

En Railway, debes configurar el servicio así:

#### Opción 1: Via Railway UI

1. **Settings → Build**
     - Builder: **Dockerfile**
     - Dockerfile Path: **Dockerfile.model_server** ← (NO incluir `backend/`)
     - Root Directory: **backend** ← (CRÍTICO: debe ser `backend`)

2. **Settings → Deploy**
     - Start Command: `uvicorn model_server.main:app --host 0.0.0.0 --port $PORT`

#### Opción 2: Via Railway CLI

```bash
# Crear servicio (desde la raíz del proyecto)
railway service create indexing-model-server

# Configurar build
railway service update \
  --root-directory backend \
  --dockerfile-path Dockerfile.model_server
```

### 📝 Configuración de Variables

```bash
railway variables set \
  PORT=9000 \
  INDEXING_ONLY=True \
  DOCUMENT_ENCODER_MODEL=intfloat/e5-base-v2
```

### ⚠️ Troubleshooting

**Error: `/model_server: not found`**

Esto ocurre cuando el Root Directory NO está configurado como `backend`. Railway necesita:

- **Root Directory = `backend`** (el contexto de build)
- **Dockerfile Path = `Dockerfile.model_server`** (relativo al Root Directory)

Si ves este error, verifica en **Settings → Build** que Root Directory sea exactamente `backend`.

### 🗂️ Volumen (Opcional)

- **Mount Path**: `/app/.cache/huggingface`
- **Propósito**: Cachear modelos descargados

---

## 7. API Server

### 📦 Tipo de Servicio

**Build from Dockerfile**

### 📂 Ubicación del Dockerfile

```
backend/Dockerfile
```

### ⚙️ Variables de Entorno (Completas)

```bash
# ═══════════════════════════════════════════════════════════
# PUERTO
# ═══════════════════════════════════════════════════════════
PORT=8080

# ═══════════════════════════════════════════════════════════
# AUTENTICACIÓN
# ═══════════════════════════════════════════════════════════
AUTH_TYPE=basic
# Opciones: basic, disabled, google_oauth, oidc, saml

# ═══════════════════════════════════════════════════════════
# POSTGRESQL (Relational Database)
# ═══════════════════════════════════════════════════════════
POSTGRES_HOST=${{Postgres.RAILWAY_PRIVATE_DOMAIN}}
POSTGRES_PORT=${{Postgres.PORT}}
POSTGRES_USER=${{Postgres.PGUSER}}
POSTGRES_PASSWORD=${{Postgres.PGPASSWORD}}
POSTGRES_DB=${{Postgres.PGDATABASE}}

# ═══════════════════════════════════════════════════════════
# REDIS (Cache)
# ═══════════════════════════════════════════════════════════
REDIS_HOST=${{Redis.RAILWAY_PRIVATE_DOMAIN}}
REDIS_PORT=${{Redis.PORT}}
REDIS_PASSWORD=
REDIS_DB=0
REDIS_SSL=false

# ═══════════════════════════════════════════════════════════
# VESPA (Vector Search)
# ═══════════════════════════════════════════════════════════
VESPA_HOST=${{vespa.RAILWAY_PRIVATE_DOMAIN}}
VESPA_PORT=8081
VESPA_TENANT_PORT=19071

# ═══════════════════════════════════════════════════════════
# MINIO (File Storage)
# ═══════════════════════════════════════════════════════════
FILE_STORE_BACKEND=s3
S3_ENDPOINT_URL=http://${{minio.RAILWAY_PRIVATE_DOMAIN}}:9000
S3_AWS_ACCESS_KEY_ID=${{minio.MINIO_ROOT_USER}}
S3_AWS_SECRET_ACCESS_KEY=${{minio.MINIO_ROOT_PASSWORD}}
S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket
S3_REGION=us-east-1

# ═══════════════════════════════════════════════════════════
# MODEL SERVERS
# ═══════════════════════════════════════════════════════════
MODEL_SERVER_HOST=${{inference-model-server.RAILWAY_PRIVATE_DOMAIN}}
MODEL_SERVER_PORT=9000
INDEXING_MODEL_SERVER_HOST=${{indexing-model-server.RAILWAY_PRIVATE_DOMAIN}}
INDEXING_MODEL_SERVER_PORT=9000

# ═══════════════════════════════════════════════════════════
# LLM CONFIGURATION
# ═══════════════════════════════════════════════════════════
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_MODEL_NAME=gpt-4
OPENAI_EMBEDDINGS_MODEL=text-embedding-ada-002

# Anthropic (opcional)
ANTHROPIC_API_KEY=sk-ant-...

# ═══════════════════════════════════════════════════════════
# APLICACIÓN
# ═══════════════════════════════════════════════════════════
WEB_DOMAIN=https://your-app.up.railway.app
LOG_LEVEL=info
SECRET_KEY=your-secret-key-here-change-in-production

# Workers
USE_LIGHTWEIGHT_BACKGROUND_WORKER=true

# Craft (opcional, deshabilitado por defecto)
ENABLE_CRAFT=false

# OpenSearch (opcional, deshabilitado por defecto)
ENABLE_OPENSEARCH_INDEXING_FOR_ONYX=false
```

### 🔌 Puerto

- **Puerto por defecto**: `8080`
- **Configurable via**: Variable `PORT` en Railway
- **Railway expone automáticamente** este puerto (expose público opcional)

### 🐳 Build Configuration

**⚠️ IMPORTANTE: Configuración correcta del Build Context**

En Railway, debes configurar el servicio así:

#### Via Railway UI

1. **Settings → Build**
     - Builder: **Dockerfile**
     - Dockerfile Path: **Dockerfile** ← (NO incluir `backend/`)
     - Root Directory: **backend** ← (CRÍTICO: debe ser `backend`)

2. **Settings → Deploy**
     - Start Command: `/bin/sh -c "alembic upgrade head && echo 'Starting Onyx Api Server' && uvicorn onyx.main:app --host 0.0.0.0 --port $PORT"`

#### Via Railway CLI

```bash
# Crear servicio (desde la raíz del proyecto)
railway service create api-server

# Configurar build
railway service update \
  --root-directory backend \
  --dockerfile-path Dockerfile
```

### 📝 Configuración de Variables Mínimas

```bash
# Set minimal required variables
railway variables set \
  PORT=8080 \
  AUTH_TYPE=basic \
  FILE_STORE_BACKEND=s3 \
  USE_LIGHTWEIGHT_BACKGROUND_WORKER=true \
  LOG_LEVEL=info
```

### 🔗 Service Dependencies

```bash
# En la UI de Railway, configurar dependencias:
Depends on:
  - Postgres
  - Redis
  - minio
  - vespa
  - inference-model-server
  - indexing-model-server
```

---

## 8. Background Worker

### 📦 Tipo de Servicio

**Build from Dockerfile**

### 📂 Ubicación del Dockerfile

```
backend/Dockerfile
```

### ⚙️ Variables de Entorno (Completas)

```bash
# ═══════════════════════════════════════════════════════════
# WORKER CONFIGURATION
# ═══════════════════════════════════════════════════════════
USE_LIGHTWEIGHT_BACKGROUND_WORKER=true

# ═══════════════════════════════════════════════════════════
# POSTGRESQL (Relational Database)
# ═══════════════════════════════════════════════════════════
POSTGRES_HOST=${{Postgres.RAILWAY_PRIVATE_DOMAIN}}
POSTGRES_PORT=${{Postgres.PORT}}
POSTGRES_USER=${{Postgres.PGUSER}}
POSTGRES_PASSWORD=${{Postgres.PGPASSWORD}}
POSTGRES_DB=${{Postgres.PGDATABASE}}

# ═══════════════════════════════════════════════════════════
# REDIS (Cache & Celery)
# ═══════════════════════════════════════════════════════════
REDIS_HOST=${{Redis.RAILWAY_PRIVATE_DOMAIN}}
REDIS_PORT=${{Redis.PORT}}
REDIS_PASSWORD=
REDIS_DB=0
REDIS_SSL=false

# ═══════════════════════════════════════════════════════════
# VESPA (Vector Search)
# ═══════════════════════════════════════════════════════════
VESPA_HOST=${{vespa.RAILWAY_PRIVATE_DOMAIN}}
VESPA_PORT=8081
VESPA_TENANT_PORT=19071

# ═══════════════════════════════════════════════════════════
# MINIO (File Storage)
# ═══════════════════════════════════════════════════════════
FILE_STORE_BACKEND=s3
S3_ENDPOINT_URL=http://${{minio.RAILWAY_PRIVATE_DOMAIN}}:9000
S3_AWS_ACCESS_KEY_ID=${{minio.MINIO_ROOT_USER}}
S3_AWS_SECRET_ACCESS_KEY=${{minio.MINIO_ROOT_PASSWORD}}
S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket
S3_REGION=us-east-1

# ═══════════════════════════════════════════════════════════
# MODEL SERVERS
# ═══════════════════════════════════════════════════════════
MODEL_SERVER_HOST=${{inference-model-server.RAILWAY_PRIVATE_DOMAIN}}
MODEL_SERVER_PORT=9000
INDEXING_MODEL_SERVER_HOST=${{indexing-model-server.RAILWAY_PRIVATE_DOMAIN}}
INDEXING_MODEL_SERVER_PORT=9000

# ═══════════════════════════════════════════════════════════
# API SERVER CONNECTION (para Discord bot, etc.)
# ═══════════════════════════════════════════════════════════
API_SERVER_PROTOCOL=http
API_SERVER_HOST=${{api-server.RAILWAY_PRIVATE_DOMAIN}}
API_SERVER_PORT=8080

# ═══════════════════════════════════════════════════════════
# LLM CONFIGURATION
# ═══════════════════════════════════════════════════════════
OPENAI_API_KEY=sk-...
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_MODEL_NAME=gpt-4

# ═══════════════════════════════════════════════════════════
# DISCORD BOT (opcional)
# ═══════════════════════════════════════════════════════════
DISCORD_BOT_TOKEN=
DISCORD_BOT_INVOKE_CHAR=!

# ═══════════════════════════════════════════════════════════
# APLICACIÓN
# ═══════════════════════════════════════════════════════════
LOG_LEVEL=info
SECRET_KEY=your-secret-key-here-change-in-production

# Craft (opcional)
ENABLE_CRAFT=false

# OpenSearch (opcional)
ENABLE_OPENSEARCH_INDEXING_FOR_ONYX=false
```

### 🔌 Puerto

**No expone puerto** - Ejecuta workers de Celery en background

### 🐳 Build Configuration

**⚠️ IMPORTANTE: Configuración correcta del Build Context**

En Railway, debes configurar el servicio así:

#### Via Railway UI

1. **Settings → Build**
     - Builder: **Dockerfile**
     - Dockerfile Path: **Dockerfile** ← (NO incluir `backend/`)
     - Root Directory: **backend** ← (CRÍTICO: debe ser `backend`)

2. **Settings → Deploy**
     - Start Command: `/bin/sh -c "if [ -f /app/scripts/setup_craft_templates.sh ]; then /app/scripts/setup_craft_templates.sh; fi && /app/scripts/supervisord_entrypoint.sh"`

#### Via Railway CLI

```bash
# Crear servicio (desde la raíz del proyecto)
railway service create background-worker

# Configurar build
railway service update \
  --root-directory backend \
  --dockerfile-path Dockerfile
```

### 📝 Configuración de Variables Mínimas

```bash
railway service create background-worker

# Set minimal required variables
railway variables set \
  USE_LIGHTWEIGHT_BACKGROUND_WORKER=true \
  FILE_STORE_BACKEND=s3 \
  LOG_LEVEL=info
```

### 🔗 Service Dependencies

```bash
# En la UI de Railway, configurar dependencias:
Depends on:
  - Postgres
  - Redis
  - minio
  - vespa
  - inference-model-server
  - indexing-model-server
```

---

## 9. Web Server

### 📦 Tipo de Servicio

**Build from Dockerfile**

### 📂 Ubicación del Dockerfile

```
web/Dockerfile
```

### ⚙️ Variables de Entorno

```bash
# ═══════════════════════════════════════════════════════════
# PUERTO
# ═══════════════════════════════════════════════════════════
PORT=3000

# ═══════════════════════════════════════════════════════════
# API SERVER CONNECTION
# ═══════════════════════════════════════════════════════════
INTERNAL_URL=http://${{api-server.RAILWAY_PRIVATE_DOMAIN}}:8080
NEXT_PUBLIC_API_URL=https://your-app.up.railway.app

# ═══════════════════════════════════════════════════════════
# AUTENTICACIÓN (Build-time variables)
# ═══════════════════════════════════════════════════════════
NEXT_PUBLIC_DISABLE_LOGOUT=false
NEXT_PUBLIC_FORGOT_PASSWORD_ENABLED=true

# ═══════════════════════════════════════════════════════════
# THEME (Enterprise Edition - opcional)
# ═══════════════════════════════════════════════════════════
NEXT_PUBLIC_THEME=

# ═══════════════════════════════════════════════════════════
# BRANDING
# ═══════════════════════════════════════════════════════════
NEXT_PUBLIC_DO_NOT_USE_TOGGLE_OFF_DANSWER_POWERED=false

# ═══════════════════════════════════════════════════════════
# NODE OPTIONS (para build)
# ═══════════════════════════════════════════════════════════
NODE_OPTIONS=--max-old-space-size=4096
```

### 🔌 Puerto

- **Puerto por defecto**: `3000`
- **Configurable via**: Variable `PORT` en Railway
- **Este es el puerto público** - Railway debe exponerlo

### 🐳 Build Configuration

**⚠️ IMPORTANTE: Configuración correcta del Build Context**

En Railway, debes configurar el servicio así:

#### Via Railway UI

1. **Settings → Build**
     - Builder: **Dockerfile**
     - Dockerfile Path: **Dockerfile** ← (NO incluir `web/`)
     - Root Directory: **web** ← (CRÍTICO: debe ser `web`)

2. **Settings → Deploy**
     - Start Command: (dejar vacío - usa el definido en Dockerfile: `node server.js`)

#### Via Railway CLI

```bash
# Crear servicio (desde la raíz del proyecto)
railway service create web-server

# Configurar build
railway service update \
  --root-directory web \
  --dockerfile-path Dockerfile
```

### 📝 Configuración de Variables

```bash
railway service create web-server

# Set variables
railway variables set \
  PORT=3000 \
  NODE_OPTIONS="--max-old-space-size=4096" \
  NEXT_PUBLIC_DISABLE_LOGOUT=false \
  NEXT_PUBLIC_FORGOT_PASSWORD_ENABLED=true
```

### 🌐 Networking

```bash
# Este servicio DEBE tener un dominio público
# Railway lo asignará automáticamente: xxxxxx.up.railway.app

# Configurar NEXT_PUBLIC_API_URL al dominio público:
railway variables set \
  NEXT_PUBLIC_API_URL=https://tu-app.up.railway.app
```

### 🔗 Service Dependencies

```bash
# En la UI de Railway, configurar:
Depends on:
  - api-server
```

---

## 📊 RESUMEN DE PUERTOS

| Servicio          | Puerto Default | Configurable    | Exponer Público |
| ----------------- | -------------- | --------------- | --------------- |
| PostgreSQL        | 5432           | ❌ No (Railway) | ❌ No           |
| Redis             | 6379           | ❌ No (Railway) | ❌ No           |
| MinIO             | 9000 / 9001    | ✅ Sí           | ❌ No           |
| Vespa             | 19071 / 8081   | ❌ No           | ❌ No           |
| Inference Model   | 9000           | ✅ Sí           | ❌ No           |
| Indexing Model    | 9000           | ✅ Sí           | ❌ No           |
| API Server        | 8080           | ✅ Sí           | ⚠️ Opcional     |
| Background Worker | N/A            | N/A             | ❌ No           |
| Web Server        | 3000           | ✅ Sí           | ✅ **SÍ**       |

---

## 🗂️ RESUMEN DE DOCKERFILES

| Servicio          | Dockerfile                | Root Directory |
| ----------------- | ------------------------- | -------------- |
| PostgreSQL        | ❌ Manejado               | N/A            |
| Redis             | ❌ Manejado               | N/A            |
| MinIO             | ❌ Docker Image           | N/A            |
| Vespa             | ❌ Docker Image           | N/A            |
| Inference Model   | `Dockerfile.model_server` | `backend/`     |
| Indexing Model    | `Dockerfile.model_server` | `backend/`     |
| API Server        | `Dockerfile`              | `backend/`     |
| Background Worker | `Dockerfile`              | `backend/`     |
| Web Server        | `Dockerfile`              | `web/`         |

---

## 🚀 COMANDO RÁPIDO: CONFIGURAR TODAS LAS VARIABLES

### 1. PostgreSQL (Manejado)

```bash
# Railway crea estas automáticamente
railway add --database postgres
```

### 2. Redis (Manejado)

```bash
# Railway crea estas automáticamente
railway add --database redis
```

### 3. MinIO

```bash
railway variables set \
  MINIO_ROOT_USER=minioadmin \
  MINIO_ROOT_PASSWORD=$(openssl rand -base64 32) \
  MINIO_DEFAULT_BUCKETS=onyx-file-store-bucket \
  PORT=9000
```

### 4. Vespa

```bash
railway variables set \
  VESPA_SKIP_UPGRADE_CHECK=true
```

### 5. Inference Model Server

```bash
railway variables set \
  PORT=9000 \
  INDEXING_ONLY=False \
  MODEL_NAME=intfloat/e5-base-v2
```

### 6. Indexing Model Server

```bash
railway variables set \
  PORT=9000 \
  INDEXING_ONLY=True \
  DOCUMENT_ENCODER_MODEL=intfloat/e5-base-v2
```

### 7. API Server

```bash
railway variables set \
  PORT=8080 \
  AUTH_TYPE=basic \
  FILE_STORE_BACKEND=s3 \
  USE_LIGHTWEIGHT_BACKGROUND_WORKER=true \
  LOG_LEVEL=info \
  SECRET_KEY=$(openssl rand -base64 32) \
  POSTGRES_HOST='${{Postgres.RAILWAY_PRIVATE_DOMAIN}}' \
  POSTGRES_PORT='${{Postgres.PORT}}' \
  POSTGRES_USER='${{Postgres.PGUSER}}' \
  POSTGRES_PASSWORD='${{Postgres.PGPASSWORD}}' \
  POSTGRES_DB='${{Postgres.PGDATABASE}}' \
  REDIS_HOST='${{Redis.RAILWAY_PRIVATE_DOMAIN}}' \
  REDIS_PORT='${{Redis.PORT}}' \
  VESPA_HOST='${{vespa.RAILWAY_PRIVATE_DOMAIN}}' \
  VESPA_PORT=8081 \
  S3_ENDPOINT_URL='http://${{minio.RAILWAY_PRIVATE_DOMAIN}}:9000' \
  S3_AWS_ACCESS_KEY_ID='${{minio.MINIO_ROOT_USER}}' \
  S3_AWS_SECRET_ACCESS_KEY='${{minio.MINIO_ROOT_PASSWORD}}' \
  S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket \
  MODEL_SERVER_HOST='${{inference-model-server.RAILWAY_PRIVATE_DOMAIN}}' \
  INDEXING_MODEL_SERVER_HOST='${{indexing-model-server.RAILWAY_PRIVATE_DOMAIN}}' \
  OPENAI_API_KEY=tu-clave-aqui
```

### 8. Background Worker

```bash
# Copiar exactamente las mismas variables del API Server
# Además añadir:
railway variables set \
  API_SERVER_PROTOCOL=http \
  API_SERVER_HOST='${{api-server.RAILWAY_PRIVATE_DOMAIN}}' \
  API_SERVER_PORT=8080
```

### 9. Web Server

```bash
railway variables set \
  PORT=3000 \
  NODE_OPTIONS="--max-old-space-size=4096" \
  NEXT_PUBLIC_DISABLE_LOGOUT=false \
  NEXT_PUBLIC_FORGOT_PASSWORD_ENABLED=true \
  NEXT_PUBLIC_DO_NOT_USE_TOGGLE_OFF_DANSWER_POWERED=false \
  INTERNAL_URL='http://${{api-server.RAILWAY_PRIVATE_DOMAIN}}:8080'

# Después de obtener el dominio público:
railway variables set \
  NEXT_PUBLIC_API_URL=https://tu-dominio.up.railway.app
```

---

## ⚠️ NOTAS IMPORTANTES

### Variables con Referencias de Railway

Cuando uses `${{service.VARIABLE}}` en Railway:

1. **Usa comillas simples** en la CLI:

     ```bash
     railway variables set POSTGRES_HOST='${{Postgres.RAILWAY_PRIVATE_DOMAIN}}'
     ```

2. **En la UI de Railway**, no uses comillas - Railway las interpreta automáticamente

3. **El servicio debe existir** antes de referenciar sus variables

### Build Arguments vs Runtime Variables

- **Build Arguments**: Se usan durante `docker build`
     - Ejemplo: `ENABLE_CRAFT`, `NODE_OPTIONS`, `NEXT_PUBLIC_*`
     - Se configuran en la sección "Build" de Railway

- **Runtime Variables**: Se usan cuando el contenedor está ejecutándose
     - Ejemplo: `PORT`, `POSTGRES_HOST`, `OPENAI_API_KEY`
     - Se configuran en la sección "Variables" de Railway

### Orden de Despliegue

Para evitar errores de referencias:

1. PostgreSQL, Redis (manejados)
2. MinIO, Vespa (imágenes)
3. Model Servers (inference, indexing)
4. API Server + Background Worker
5. Web Server

---

## 📖 PRÓXIMOS PASOS

1. **Revisa** este documento completo
2. **Copia** las variables necesarias para cada servicio
3. **Personaliza** valores como `OPENAI_API_KEY`, `SECRET_KEY`
4. **Sigue** el README.md para el proceso completo de despliegue
5. **Consulta** CHECKLIST.md para verificación exhaustiva

---

## 🆘 TROUBLESHOOTING COMÚN

### ❌ Error: `/model_server: not found` (Model Servers)

**Causa:** El Root Directory no está configurado correctamente en Railway.

**Solución:**

1. Ve a **Settings → Build** del servicio
2. Verifica que **Root Directory = `backend`**
3. Verifica que **Dockerfile Path = `Dockerfile.model_server`** (sin `backend/`)
4. Guarda y redeploy

```bash
# Via CLI
railway service update \
  --root-directory backend \
  --dockerfile-path Dockerfile.model_server
```

---

### ❌ Error: Archivos no encontrados en otros servicios

**Problema:** Errores COPY en Dockerfile por archivos no encontrados

**Solución por servicio:**

| Servicio          | Root Directory | Dockerfile Path           |
| ----------------- | -------------- | ------------------------- |
| Inference Model   | `backend`      | `Dockerfile.model_server` |
| Indexing Model    | `backend`      | `Dockerfile.model_server` |
| API Server        | `backend`      | `Dockerfile`              |
| Background Worker | `backend`      | `Dockerfile`              |
| Web Server        | `web`          | `Dockerfile`              |

**Comando CLI genérico:**

```bash
railway service update \
  --root-directory <ROOT_DIR> \
  --dockerfile-path <DOCKERFILE>
```

---

### ❌ Error: Variables de Railway no se resuelven

**Síntomas:** Variables como `${{Postgres.PGHOST}}` aparecen literales

**Causas y Soluciones:**

1. **El servicio referenciado no existe:**
     - Asegúrate de crear primero PostgreSQL, Redis, MinIO, etc.
     - Los nombres deben coincidir exactamente (case-sensitive)

2. **Sintaxis incorrecta en CLI:**

     ```bash
     # ❌ INCORRECTO (sin comillas)
     railway variables set POSTGRES_HOST=${{Postgres.RAILWAY_PRIVATE_DOMAIN}}

     # ✅ CORRECTO (con comillas simples)
     railway variables set POSTGRES_HOST='${{Postgres.RAILWAY_PRIVATE_DOMAIN}}'
     ```

3. **En la UI de Railway:**
     - NO uses comillas - Railway las interpreta automáticamente
     - Simplemente escribe: `${{Postgres.RAILWAY_PRIVATE_DOMAIN}}`

---

### ❌ Error: Puerto ya en uso / Conflictos de red

**No debería ocurrir** - Railway asigna dominios privados únicos por servicio.

Sin embargo, si ves errores:

- Verifica que cada servicio tenga su propio nombre único
- Los puertos se asignan internamente, no hay conflictos

---

### ❌ Error: Vespa no inicia / Health check fail

**Causa común:** Volumen muy pequeño o memoria insuficiente

**Solución:**

1. Aumenta el volumen a mínimo **20GB** (recomendado 50GB)
2. Aumenta la RAM del servicio (Railway Pro: 8GB+)
3. Verifica logs: `railway logs -s vespa`

---

### ❌ Error: MinIO bucket no se crea automáticamente

**Síntoma:** API Server falla con errores S3 "bucket not found"

**Solución:**

```bash
# Verifica que la variable esté configurada
railway variables list -s minio | grep MINIO_DEFAULT_BUCKETS

# Debe mostrar:
# MINIO_DEFAULT_BUCKETS=onyx-file-store-bucket

# Si no existe, añádela:
railway variables set MINIO_DEFAULT_BUCKETS=onyx-file-store-bucket -s minio

# Redeploy MinIO
railway redeploy -s minio
```

---

### ❌ Error: Web Server no se conecta al API Server

**Síntomas:** Frontend carga pero no puede hacer requests al backend

**Checklist:**

1. ✅ **API Server está corriendo:**

     ```bash
     railway logs -s api-server
     ```

2. ✅ **INTERNAL_URL está configurado correctamente:**

     ```bash
     # Debe ser:
     INTERNAL_URL=http://${{api-server.RAILWAY_PRIVATE_DOMAIN}}:8080
     ```

3. ✅ **Web Server tiene dependencia en API Server:**
     - En Railway UI → web-server → Settings → Dependencies
     - Debe listar `api-server`

4. ✅ **NEXT_PUBLIC_API_URL usar dominio público:**
     ```bash
     # Debe apuntar al dominio público del web server:
     NEXT_PUBLIC_API_URL=https://tu-app.up.railway.app
     ```

---

### 🔍 Comandos de Debug

```bash
# Ver logs en tiempo real
railway logs -s <service-name> --follow

# Ver últimas 100 líneas
railway logs -s <service-name> --tail 100

# Listar todas las variables de un servicio
railway variables list -s <service-name>

# Ver información del servicio
railway service <service-name>

# Forzar redeploy
railway redeploy -s <service-name>

# Verificar estado de todos los servicios
railway status
```

---

### 📞 Soporte Adicional

Si encuentras problemas no listados aquí:

1. **Revisa logs:** `railway logs -s <service-name>`
2. **Verifica variables:** `railway variables list -s <service-name>`
3. **Revisa dependencias:** Settings → Dependencies en Railway UI
4. **Consulta documentación:**
     - [README.md](./README.md) - Guía completa
     - [CHECKLIST.md](./CHECKLIST.md) - Verificación paso a paso
     - [BEST_PRACTICES.md](./BEST_PRACTICES.md) - Optimizaciones

---

¿Listo para desplegar? 🚀
