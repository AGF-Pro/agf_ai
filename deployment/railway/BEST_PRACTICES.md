# 🎯 Mejores Prácticas y Optimizaciones para Railway

## 🏗️ Arquitectura Recomendada

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    Railway Edge Network
                      (SSL/TLS, CDN)
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───▼───┐         ┌─────▼─────┐      ┌─────▼─────┐
    │  Web  │────────▶│ API Server│◀─────│Background │
    │Server │         │   :8080   │      │  Worker   │
    │ :3000 │         └─────┬─────┘      └─────┬─────┘
    └───────┘               │                   │
                            │                   │
        ┌───────────────────┼───────────────────┼──────────────────┐
        │                   │                   │                  │
    ┌───▼────┐         ┌────▼────┐         ┌───▼───┐   ┌────▼────┐   ┌───▼───┐
    │Postgres│         │  Redis  │         │ MinIO │   │ Vespa   │   │ Model │
    │  (DB)  │         │ (Cache) │         │  S3   │   │ :8081   │   │Servers│
    └────────┘         └─────────┘         └───────┘   └─────────┘   └───────┘
```

## 💡 Optimizaciones de Configuración

### 1. Variables de Entorno por Servicio

**Estrategia de Variables:**

- **Shared Variables**: Para configuración común (API keys, auth, etc.)
- **Service Variables**: Para configuración específica (URLs, puertos)
- **Referencias**: Para conexión entre servicios

**Ejemplo de referencia entre servicios:**

```bash
# En API Server
VESPA_HOST=${{vespa.RAILWAY_PRIVATE_DOMAIN}}

# NO uses IPs o hostnames hardcodeados
# ❌ VESPA_HOST=10.0.0.5
# ✅ VESPA_HOST=${{vespa.RAILWAY_PRIVATE_DOMAIN}}
```

### 2. Uso de Dominios Privados

Railway proporciona dos tipos de dominios:

- **PUBLIC_DOMAIN**: Accesible desde internet
- **PRIVATE_DOMAIN**: Solo dentro del proyecto Railway (más rápido, sin costo de egress)

**Regla de oro:**

- Usa `.RAILWAY_PRIVATE_DOMAIN` para comunicación interna
- Usa `.RAILWAY_PUBLIC_DOMAIN` solo cuando sea necesario desde fuera

```bash
# ✅ Correcto - Comunicación interna
INTERNAL_URL=http://${{api-server.RAILWAY_PRIVATE_DOMAIN}}:8080

# ❌ Incorrecto - Usando URL pública innecesariamente
INTERNAL_URL=https://${{api-server.RAILWAY_PUBLIC_DOMAIN}}
```

### 3. Gestión de Recursos

**Asignación recomendada por servicio:**

| Servicio               | RAM   | CPU | Disco    | Notas                        |
| ---------------------- | ----- | --- | -------- | ---------------------------- |
| web-server             | 512MB | 0.5 | -        | Stateless, escala horizontal |
| api-server             | 1GB   | 1   | -        | Puede escalar horizontal     |
| background-worker      | 2GB   | 2   | -        | Processor intensivo          |
| model-server-inference | 2-4GB | 2   | 5GB      | Depende del modelo           |
| model-server-indexing  | 2-4GB | 2   | 5GB      | Depende del modelo           |
| minio                  | 512MB | 0.5 | 20-100GB | Storage para documentos      |
| vespa                  | 2-4GB | 2   | 10-50GB  | Crece con data               |
| postgres               | 1-2GB | 1   | 10-100GB | Railway managed              |
| redis                  | 256MB | 0.5 | -        | Ephemeral o managed          |
| vespa                  | 2-4GB | 2   | 10-50GB  | Crece con data               |
| postgres               | 1-2GB | 1   | 10-100GB | Railway managed              |
| redis                  | 256MB | 0.5 | -        | Ephemeral o managed          |

**Scaling Strategy:**

- **Horizontal**: web-server, api-server (stateless)
- **Vertical**: model-servers, vespa, background-worker
- **Managed**: postgres, redis (Railway se encarga)

### 4. Networking Configuration

**Public vs Private:**

```yaml
# Services que DEBEN tener Public Networking:
✅ web-server (usuarios acceden desde navegador)
✅ api-server (si usas API directamente desde apps móviles)

# Services que NO necesitan Public Networking:
❌ background-worker (solo comunicación interna)
❌ model-servers (solo API server los llama)
❌ vespa (solo API server lo llama)
❌ postgres (Railway managed, ya tiene networking privado)
❌ redis (Railway managed, ya tiene networking privado)
```

Deshabilitar Public Networking cuando no se necesite:

- Reduce superficie de ataque
- Reduce costos de egress
- Mejora latencia interna

### 5. Volúmenes Persistentes

**Cuándo usar volúmenes:**

```yaml
# ✅ Necesario
vespa:
     volume: /opt/vespa/var # Índices de búsqueda

model-servers:
     volume: /app/.cache/huggingface/ # Cache de modelos ML

api-server:
     volume: /app/file-system # Si FILE_STORE_BACKEND=filesystem

# ❌ No necesario (puede usar volumen para logs si quieres)
background-worker: []
web-server: []
```

**Tamaños recomendados:**

- Vespa: 10GB inicial, crece con documentos
- Model cache: 5GB por servidor
- File system: 10GB inicial, monitorear crecimiento

### 6. Service Dependencies

**Orden de inicio correcto:**

```
1. postgres, redis (primero, servicios base)
2. vespa (segundo, necesita inicializarse)
3. model-servers (tercero, descargan modelos)
4. api-server (cuarto, depende de todo lo anterior)
5. background-worker (cuarto, depende de todo lo anterior)
6. web-server (quinto, depende de api-server)
```

Configurar en Railway:

```bash
# Para cada servicio, en Settings > Dependencies
api-server:
  depends_on:
    - postgres
    - redis
    - vespa
    - model-server-inference
    - model-server-indexing

background-worker:
  depends_on:
    - postgres
    - redis
    - vespa
    - model-server-inference
    - model-server-indexing
    - api-server  # Importante!

web-server:
  depends_on:
    - api-server
```

## 🔒 Seguridad

### 1. Authentication

**Progresión recomendada:**

```bash
# Stage 1: Desarrollo/Testing
AUTH_TYPE=disabled

# Stage 2: Staging
AUTH_TYPE=basic
VALID_EMAIL_DOMAINS=tuempresa.com

# Stage 3: Producción
AUTH_TYPE=oidc  # O SAML si lo necesitas
# Configurar Google/Okta/etc.
```

### 2. Secrets Management

**Railway tiene tres niveles de variables:**

1. **Project Variables** (compartidas): Para config no sensible
2. **Service Variables**: Para config específica
3. **Secrets**: Para API keys, tokens (encriptados)

**Ejemplo:**

```bash
# ✅ Como Secret
railway variables set OPENAI_API_KEY="sk-..." --secret

# ✅ Como Variable normal
railway variables set LOG_LEVEL="info"

# ❌ Nunca en código
const apiKey = "sk-abc123..."  # NUNCA!
```

### 3. Database Security

```bash
# ✅ Buenas prácticas
- Usar Railway managed PostgreSQL (backups automáticos)
- Habilitar SSL para conexiones
- Limitar conexiones desde servicios específicos
- Rotar credenciales regularmente

# ❌ Evitar
- Exponer PostgreSQL públicamente
- Usar credenciales por defecto
- Guardar backups sin encriptar
```

### 4. Rate Limiting

Railway tiene rate limiting automático, pero puedes añadir a nivel app:

```python
# En backend/onyx/server/middleware.py
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/api/chat")
@limiter.limit("10/minute")  # 10 requests por minuto
async def chat_endpoint():
    ...
```

## 📊 Monitoreo y Observabilidad

### 1. Métricas Built-in de Railway

Railway proporciona automáticamente:

- CPU usage
- Memory usage
- Disk usage
- Network in/out
- HTTP requests
- Response times

Acceso: Dashboard > Servicio > Metrics

### 2. Logging Strategy

**Niveles de log por ambiente:**

```bash
# Development
LOG_LEVEL=debug
LOG_ONYX_MODEL_INTERACTIONS=true
LOG_VESPA_TIMING_INFORMATION=true

# Staging
LOG_LEVEL=info
LOG_ONYX_MODEL_INTERACTIONS=false

# Production
LOG_LEVEL=warning
LOG_ONYX_MODEL_INTERACTIONS=false
DISABLE_TELEMETRY=true
```

**Viewing logs:**

```bash
# Logs en tiempo real
railway logs -f

# Logs de servicio específico
railway logs -s api-server -f

# Últimas 100 líneas
railway logs --lines 100
```

### 3. Alertas

Configurar alertas en Railway:

- CPU > 80% por 5 minutos
- Memory > 90% por 5 minutos
- Servicio down
- Deployment failed

### 4. Health Checks

Railway hace health checks automáticos al puerto expuesto.

Puedes añadir endpoints custom:

```python
# backend/onyx/server/health.py
@router.get("/health/detailed")
async def detailed_health():
    return {
        "status": "healthy",
        "postgres": await check_postgres(),
        "redis": await check_redis(),
        "vespa": await check_vespa(),
        "model_server": await check_model_server()
    }
```

## 💰 Optimización de Costos

### 1. Reducir Egress de Red

**Egress costoso:**

```bash
# ❌ Cada llamada sale a internet
MODEL_SERVER_HOST=external-api.example.com
```

**Egress gratuito:**

```bash
# ✅ Tráfico interno de Railway
MODEL_SERVER_HOST=${{model-server.RAILWAY_PRIVATE_DOMAIN}}
```

### 2. Usar Model Servers External

Si los model servers son muy costosos en Railway:

```bash
# Opción 1: Usar OpenAI embeddings (puede ser más barato)
DOCUMENT_ENCODER_MODEL=text-embedding-3-small
DISABLE_MODEL_SERVER=true

# Opción 2: Host model servers en GPU cloud (Hugging Face Inference, etc.)
MODEL_SERVER_HOST=https://api-inference.huggingface.co/...
```

**Comparación de costos:**

| Opción | Costo mensual estimado | Pros | Contras |
| --- | --- | --- | --- |
| Railway 2x Model Servers | $40-80 | Todo en un lugar | Más caro |
| OpenAI Embeddings | $10-30 | Más barato para bajo volumen | Depende de OpenAI |
| HF Inference API | $20-40 | Flexibilidad | Latencia externa |

### 3. Lightweight Mode

```bash
# ✅ Activa esto para reducir workers
USE_LIGHTWEIGHT_BACKGROUND_WORKER=true

# Esto consolida todos los workers en uno solo
# Ahorra: ~$20-40/mes comparado con workers separados
```

### 4. Right-sizing Resources

**Monitorear uso real y ajustar:**

```bash
# Ver métricas de los últimos 7 días
railway metrics -s api-server --range 7d

# Si CPU promedio < 30%, reduce vCPUs
# Si Memory promedio < 50%, reduce RAM
```

### 5. Optimizar File Storage

```bash
# Opción 1: MinIO (recomendado - configuración nativa de Onyx)
FILE_STORE_BACKEND=s3
S3_ENDPOINT_URL=http://${{minio.RAILWAY_PRIVATE_DOMAIN}}:9000
S3_AWS_ACCESS_KEY_ID=minioadmin
S3_AWS_SECRET_ACCESS_KEY=minioadmin
S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket

# Opción 2: PostgreSQL (más simple pero menos performante)
FILE_STORE_BACKEND=postgres

# Opción 3: S3 Externo (AWS/GCS - para alto volumen)
FILE_STORE_BACKEND=s3
S3_ENDPOINT_URL=https://s3.amazonaws.com
S3_AWS_ACCESS_KEY_ID=<aws-key>
S3_AWS_SECRET_ACCESS_KEY=<aws-secret>
# Usa S3 Intelligent-Tiering para optimizar costos
```

**Recomendación:** Usa MinIO en Railway para mejor rendimiento y escalabilidad.

## 🚀 CI/CD Best Practices

### 1. Estrategia de Branches

```
main (production) ──▶ Auto-deploy a Railway
  │
  ├── staging ──────▶ Auto-deploy a Railway staging project
  │
  └── develop ──────▶ Manual deploy / PR previews
```

### 2. Preview Deployments

Railway puede crear deployments temporales por PR:

Settings > Deploys > Enable PR Deploys

**Costos:** Solo pagas mientras el PR está abierto

### 3. Deployment Strategies

**Rolling Update (Default):**

```yaml
# Railway hace esto automáticamente
# Zero-downtime deployments
```

**Manual Control:**

```bash
# Prevenir auto-deploy
railway service settings set --auto-deploy=false

# Deploy manual
railway up -s api-server
```

### 4. Rollback

```bash
# Ver deployments
railway deployments

# Rollback al anterior
railway rollback

# Rollback a específico
railway rollback <deployment-id>
```

## 🔄 Backup y Disaster Recovery

### 1. Database Backups

**Automated (Railway Pro):**

- Daily backups automáticos
- Point-in-time recovery
- Retención: 7 días (configurable)

**Manual:**

```bash
# Backup manual
railway run -s postgres pg_dump -U $PGUSER $PGDATABASE > backup.sql

# Restore
railway run -s postgres psql -U $PGUSER $PGDATABASE < backup.sql
```

### 2. Volume Backups

```bash
# Snapshots de volúmenes
# Railway lo hace automáticamente en Pro plan

# Manual export
railway run -s vespa tar -czf /tmp/vespa-backup.tar.gz /opt/vespa/var
```

### 3. Disaster Recovery Plan

1. **RPO** (Recovery Point Objective): 24 horas (daily backups)
2. **RTO** (Recovery Time Objective): 4 horas

**Proceso:**

1. Crear nuevo proyecto Railway
2. Restore PostgreSQL desde backup
3. Redeploy servicios desde Git
4. Restore volúmenes si es necesario
5. Actualizar DNS (si usas custom domain)

## 📈 Scaling Guidelines

### When to Scale

**Indicadores:**

- CPU > 70% sustained
- Memory > 80% sustained
- Response time > 2s p95
- Queue backlog creciendo

### How to Scale

**Vertical (más recursos):**

```bash
# Via Railway UI
Service > Settings > Resources > Increase
```

**Horizontal (más réplicas):**

```bash
# Solo para stateless services
railway service scale web-server replicas=3
```

**Load Balancing:** Railway hace load balancing automático entre réplicas.

## 🛠️ Troubleshooting Common Issues

### Issue 1: OOM Kills

**Síntomas:**

```
Service crashed: Out of Memory
```

**Solución:**

1. Incrementar RAM del servicio
2. Revisar memory leaks
3. Optimizar queries
4. Considerar Redis para cache

### Issue 2: Slow Startup

**Síntomas:**

```
Service health checks failing
Deployment timeout
```

**Solución:**

1. Incrementar Railway timeout (si es posible)
2. Optimizar Docker image (multi-stage builds)
3. Pre-warm model servers
4. Lazy load módulos pesados

### Issue 3: Connection Refused

**Síntomas:**

```
Error: Connection refused to model-server
```

**Solución:**

1. Verificar SERVICE_DOMAIN correcto
2. Verificar Service Dependencies
3. Verificar que servicio target está running
4. Verificar port correcto en ambos lados

### Issue 4: High Latency

**Síntomas:**

```
API responses > 5s
```

**Solución:**

1. Verificar Redis está funcionando
2. Añadir indexes a queries lentas
3. Optimizar Vespa queries
4. Usar PRIVATE_DOMAIN para llamadas internas
5. Habilitar compression

## 📚 Referencias Adicionales

- [Railway Docs](https://docs.railway.app)
- [Railway Templates](https://railway.app/templates)
- [Railway Discord](https://discord.gg/railway)
- [Onyx Docs](https://docs.onyx.app)
- [PostgreSQL Performance](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Redis Best Practices](https://redis.io/topics/best-practices)
- [Vespa Documentation](https://docs.vespa.ai)

---

**Última actualización:** 2026-03-18  
**Mantenido por:** Equipo Onyx
