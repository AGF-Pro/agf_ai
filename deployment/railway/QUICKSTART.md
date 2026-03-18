# 🚂 Quick Start - Despliegue en Railway

Si ya conoces Railway y solo necesitas los comandos esenciales:

## 🎯 Setup Rápido (10 minutos)

### 1. Pre-requisitos

```bash
# Instalar Railway CLI
npm i -g @railway/cli

# Login
railway login
```

### 2. Crear Proyecto

```bash
railway init -n onyx-production
```

### 3. Añadir Servicios Gestionados

```bash
railway add --database postgres
railway add --database redis
```

### 4. Variables de Entorno

```bash
# Generar encryption key
export ENCRYPTION_KEY=$(openssl rand -base64 32)

# Set variables
railway variables set \
  AUTH_TYPE=disabled \
  ENCRYPTION_KEY_SECRET="$ENCRYPTION_KEY" \
  GEN_AI_MODEL_PROVIDER=openai \
  GEN_AI_MODEL_VERSION=gpt-4 \
  FAST_GEN_AI_MODEL_VERSION=gpt-3.5-turbo \
  OPENAI_API_KEY="<tu-key>" \
  USE_LIGHTWEIGHT_BACKGROUND_WORKER=true \
  FILE_STORE_BACKEND=s3 \
  S3_AWS_ACCESS_KEY_ID=minioadmin \
  S3_AWS_SECRET_ACCESS_KEY=minioadmin \
  S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket \
  LOG_LEVEL=info \
  DISABLE_TELEMETRY=true
```

### 5. Crear Servicios Custom (en Railway UI)

| Servicio | Image/Repo | Port | Volume |
| --- | --- | --- | --- |
| vespa | `vespaengine/vespa:8.609.39` | 8081 | `/opt/vespa/var` (10GB) |
| minio | `minio/minio:RELEASE.2025-07-23T15-54-02Z-cpuv1` | 9000 | `/data` (20GB) |
| model-server-inference | GitHub: `backend/` | 8080 | `/app/.cache/huggingface/` (5GB) |
| model-server-indexing | GitHub: `backend/` | 8080 | `/app/.cache/huggingface/` (5GB) |
| api-server | GitHub: `backend/` | 8080 | - |
| background-worker | GitHub: `backend/` | - | - |
| web-server | GitHub: `web/` | 3000 | - |

### 6. Variables por Servicio

Copiar template y añadir en Railway UI:

```bash
cat deployment/railway/env.railway.template
```

### 7. Verificar

```bash
railway status
railway logs -f
```

### 8. Acceder

```bash
# Obtener URL
railway service web-server

# Ver en browser
railway open
```

## 📝 Checklist Mínimo

- [ ] PostgreSQL running
- [ ] Redis running
- [ ] MinIO running (bucket creado automáticamente)
- [ ] Vespa running (verificar logs)
- [ ] Model servers descargaron modelos (verificar logs)
- [ ] API server migró DB (verificar logs)
- [ ] Background worker activo (verificar Celery en logs)
- [ ] Web server responde

## 🐛 Debug Rápido

```bash
# Ver logs de todos los servicios
railway logs --all

# Ver logs de servicio específico
railway logs -s api-server

# Ver variables
railway variables

# Test health
curl $(railway service api-server --url)/health
```

## 🔄 Comandos Útiles

```bash
# Status
railway status

# Logs en tiempo real
railway logs -f -s api-server

# Restart servicio
railway restart -s api-server

# Redeploy
railway up -s api-server

# Rollback
railway rollback

# Variables
railway variables                    # List
railway variables set KEY=value      # Set
railway variables delete KEY         # Delete

# Shell en servicio
railway run -s api-server bash

# PostgreSQL
railway run -s postgres psql
```

## 🚨 Troubleshooting Rápido

### Servicio no inicia

```bash
railway logs -s <service> | tail -50
```

### Error de conexión

```bash
# Verificar variables
railway variables -s api-server | grep POSTGRES

# Verificar dependencies
# Railway UI > Service > Settings > Dependencies
```

### Out of Memory

```bash
# Railway UI > Service > Settings > Resources
# Incrementar RAM
```

### Vespa no responde

```bash
# Verificar logs
railway logs -s vespa

# Puede tardar 2-3 minutos en iniciar
# Verificar que tiene 2GB+ RAM
```

## 💡 Tips

1. **Usa Private Domains** para comunicación interna
2. **Habilita Dependencies** para orden de inicio correcto
3. **Monitorea recursos** en Railway Dashboard
4. **Backups**: Railway Pro tiene backups automáticos
5. **Secrets**: Usa `--secret` flag para API keys

## 📚 Documentación Completa

- [README.md](./README.md) - Guía completa paso a paso
- [CHECKLIST.md](./CHECKLIST.md) - Checklist exhaustivo
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) - Optimizaciones
- [env.railway.template](./env.railway.template) - Variables

## 🆘 Ayuda

- Railway Docs: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- Onyx Docs: https://docs.onyx.app

---

**Estimación de tiempo:**

- Setup inicial: 10-15 minutos
- Deploy completo: 30-45 minutos
- Verificación: 10-15 minutos

**Total:** ~1-1.5 horas para producción ready deployment

**Costo estimado:** $50-100/mes (Railway Pro plan)
