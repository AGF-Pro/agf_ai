# ✅ Checklist de Despliegue en Railway

## Pre-Deploy

- [ ] Cuenta de Railway creada y verificada
- [ ] Railway CLI instalado (`npm i -g @railway/cli`)
- [ ] Autenticado en Railway (`railway login`)
- [ ] API Key de OpenAI (u otro proveedor LLM)
- [ ] Repositorio Git conectado a Railway (opcional pero recomendado)
- [ ] Docker instalado localmente (para pruebas)

## Fase 1: Configuración del Proyecto

- [ ] Proyecto creado en Railway
- [ ] Nombre del proyecto definido
- [ ] Región seleccionada (más cercana a tus usuarios)
- [ ] Plan de Railway seleccionado (Starter/Hobby/Pro)

## Fase 2: Servicios Gestionados

### PostgreSQL

- [ ] Servicio PostgreSQL añadido
- [ ] Versión: 15.x
- [ ] Plan de recursos seleccionado
- [ ] Variables generadas automáticamente verificadas:
     - [ ] `PGHOST`
     - [ ] `PGPORT`
     - [ ] `PGDATABASE`
     - [ ] `PGUSER`
     - [ ] `PGPASSWORD`
- [ ] Volumen persistente configurado
- [ ] Backups automáticos habilitados (Pro plan)

### Redis

- [ ] Servicio Redis añadido
- [ ] Versión: 7.x
- [ ] Plan de recursos seleccionado
- [ ] Variables generadas automáticamente verificadas:
     - [ ] `REDISHOST`
     - [ ] `REDISPORT`
     - [ ] `REDISPASSWORD`
- [ ] Modo ephemeral configurado (o persistente según preferencia)

## Fase 3: Variables de Entorno Compartidas

- [ ] `AUTH_TYPE` configurado (disabled para inicio, basic/oidc para prod)
- [ ] `ENCRYPTION_KEY_SECRET` generado con:
     ```bash
     openssl rand -base64 32
     ```
- [ ] `OPENAI_API_KEY` configurado
- [ ] `GEN_AI_MODEL_PROVIDER` = openai
- [ ] `GEN_AI_MODEL_VERSION` = gpt-4 (o tu preferencia)
- [ ] `FAST_GEN_AI_MODEL_VERSION` = gpt-3.5-turbo (o tu preferencia)
- [ ] `USE_LIGHTWEIGHT_BACKGROUND_WORKER` = true
- [ ] `FILE_STORE_BACKEND` = postgres
- [ ] `LOG_LEVEL` = info
- [ ] `DISABLE_TELEMETRY` = true
- [ ] `VALID_EMAIL_DOMAINS` (opcional, para restringir signup)

## Fase 4: Vespa (Motor de Búsqueda)

- [ ] Servicio "vespa" creado
- [ ] Source Type: Docker Image
- [ ] Image: `vespaengine/vespa:8.609.39`
- [ ] Port: 8081 expuesto
- [ ] Variable `VESPA_SKIP_UPGRADE_CHECK=true` configurada
- [ ] Volumen persistente añadido:
     - [ ] Mount path: `/opt/vespa/var`
     - [ ] Size: 10GB (mínimo)
- [ ] Health check configurado (opcional)
- [ ] Recursos asignados:
     - [ ] RAM: 2GB mínimo
     - [ ] CPU: 1 vCPU mínimo
- [ ] Servicio en estado "Running"
- [ ] Logs revisados (sin errores)

## Fase 5: Model Server - Inference

- [ ] Servicio "model-server-inference" creado
- [ ] Source: GitHub repo conectado
- [ ] Root Directory: `backend`
- [ ] Dockerfile Path: `Dockerfile.model_server`
- [ ] Build Command: (auto desde Dockerfile)
- [ ] Start Command: `uvicorn model_server.main:app --host 0.0.0.0 --port 8080`
- [ ] Port: 8080 configurado
- [ ] Variables específicas:
     - [ ] `MIN_THREADS_ML_MODELS=4`
     - [ ] `LOG_LEVEL=info`
     - [ ] `PORT=8080`
- [ ] Volumen añadido:
     - [ ] Mount path: `/app/.cache/huggingface/`
     - [ ] Size: 5GB
- [ ] Recursos asignados:
     - [ ] RAM: 2GB mínimo
     - [ ] CPU: 2 vCPU
- [ ] Public Networking: NO
- [ ] Servicio en estado "Running"
- [ ] Logs revisados (modelo descargado correctamente)

## Fase 6: Model Server - Indexing

- [ ] Servicio "model-server-indexing" creado
- [ ] Configuración idéntica a inference (root, dockerfile, etc.)
- [ ] Variables adicionales:
     - [ ] `INDEXING_ONLY=true`
     - [ ] `VESPA_SEARCHER_THREADS=1`
- [ ] Volumen independiente:
     - [ ] Mount path: `/app/.cache/huggingface/`
     - [ ] Size: 5GB
- [ ] Recursos asignados:
     - [ ] RAM: 2GB mínimo
     - [ ] CPU: 2 vCPU
- [ ] Public Networking: NO
- [ ] Servicio en estado "Running"

## Fase 7: API Server

- [ ] Servicio "api-server" creado
- [ ] Source: GitHub repo conectado
- [ ] Root Directory: `backend`
- [ ] Dockerfile Path: `Dockerfile`
- [ ] Start Command:
     ```bash
     /bin/sh -c "alembic upgrade head && uvicorn onyx.main:app --host 0.0.0.0 --port 8080"
     ```
- [ ] Port: 8080 configurado
- [ ] Variables configuradas (via referencias):
     - [ ] `POSTGRES_HOST=${{Postgres.PGHOST}}`
     - [ ] `POSTGRES_USER=${{Postgres.PGUSER}}`
     - [ ] `POSTGRES_PASSWORD=${{Postgres.PGPASSWORD}}`
     - [ ] `POSTGRES_DB=${{Postgres.PGDATABASE}}`
     - [ ] `POSTGRES_PORT=${{Postgres.PGPORT}}`
     - [ ] `REDIS_HOST=${{Redis.REDISHOST}}`
     - [ ] `REDIS_PORT=${{Redis.REDISPORT}}`
     - [ ] `REDIS_PASSWORD=${{Redis.REDISPASSWORD}}`
     - [ ] `VESPA_HOST=${{vespa.RAILWAY_PRIVATE_DOMAIN}}`
     - [ ] `MODEL_SERVER_HOST=${{model-server-inference.RAILWAY_PRIVATE_DOMAIN}}`
     - [ ] `INDEXING_MODEL_SERVER_HOST=${{model-server-indexing.RAILWAY_PRIVATE_DOMAIN}}`
     - [ ] `PERSISTENT_DOCUMENT_STORAGE_PATH=/app/file-system`
     - [ ] `PORT=8080`
- [ ] Volumen añadido:
     - [ ] Mount path: `/app/file-system`
     - [ ] Size: 10GB
- [ ] Service Dependencies configuradas:
     - [ ] Depende de: Postgres, Redis, Vespa, Model Servers
- [ ] Public Networking: SÍ
- [ ] Railway domain generado y anotado
- [ ] Recursos asignados:
     - [ ] RAM: 1GB mínimo
     - [ ] CPU: 1 vCPU
- [ ] Servicio en estado "Running"
- [ ] Logs revisados:
     - [ ] Migraciones ejecutadas correctamente
     - [ ] Conexiones a DB/Redis exitosas
     - [ ] Health check: `curl https://<api-url>/health` devuelve 200

## Fase 8: Background Worker

- [ ] Servicio "background-worker" creado
- [ ] Source: GitHub repo conectado
- [ ] Root Directory: `backend`
- [ ] Dockerfile Path: `Dockerfile`
- [ ] Start Command: `/app/scripts/supervisord_entrypoint.sh`
- [ ] Variables (hereda de api-server + adicionales):
     - [ ] Todas las variables de API Server
     - [ ] `USE_LIGHTWEIGHT_BACKGROUND_WORKER=true`
     - [ ] `API_SERVER_PROTOCOL=https`
     - [ ] `API_SERVER_HOST=${{api-server.RAILWAY_PUBLIC_DOMAIN}}`
- [ ] Service Dependencies:
     - [ ] Depende de: Postgres, Redis, Vespa, Model Servers, API Server
- [ ] Public Networking: NO
- [ ] Recursos asignados:
     - [ ] RAM: 2GB mínimo
     - [ ] CPU: 2 vCPU
- [ ] Servicio en estado "Running"
- [ ] Logs revisados:
     - [ ] Celery workers iniciados
     - [ ] Beat scheduler activo
     - [ ] Sin errores de conexión

## Fase 9: Web Server

- [ ] Servicio "web-server" creado
- [ ] Source: GitHub repo conectado
- [ ] Root Directory: `web`
- [ ] Dockerfile Path: `Dockerfile`
- [ ] Build Args (opcional):
     - [ ] `NEXT_PUBLIC_DISABLE_LOGOUT=false`
     - [ ] `NEXT_PUBLIC_THEME=light` (o tu preferencia)
- [ ] Port: 3000 configurado
- [ ] Variables específicas:
     - [ ] `INTERNAL_URL=http://${{api-server.RAILWAY_PRIVATE_DOMAIN}}:8080`
     - [ ] `NEXT_PUBLIC_API_URL=https://${{api-server.RAILWAY_PUBLIC_DOMAIN}}`
     - [ ] `PORT=3000`
- [ ] Service Dependencies:
     - [ ] Depende de: API Server
- [ ] Public Networking: SÍ
- [ ] Railway domain generado y anotado (ESTA ES TU URL PRINCIPAL)
- [ ] Recursos asignados:
     - [ ] RAM: 512MB mínimo
     - [ ] CPU: 0.5 vCPU
- [ ] Servicio en estado "Running"
- [ ] Web accesible desde navegador
- [ ] Logs revisados (sin errores de build o runtime)

## Fase 10: Verificación Post-Deploy

### Health Checks

- [ ] API Server health check OK:
     ```bash
     curl https://<api-server-url>/health
     ```
- [ ] Web Server accesible desde navegador
- [ ] Vespa responde:
     ```bash
     railway run -s vespa curl http://localhost:8081/state/v1/health
     ```
- [ ] Background worker procesando tareas (revisar logs)

### Connectivity Tests

- [ ] API Server puede conectar a PostgreSQL
- [ ] API Server puede conectar a Redis
- [ ] API Server puede conectar a Vespa
- [ ] API Server puede conectar a Model Servers
- [ ] Background Worker puede conectar a todos los servicios
- [ ] Web Server puede conectar a API Server

### Logs Review

- [ ] Todos los servicios en estado "Running"
- [ ] Sin errores críticos en logs
- [ ] Migraciones DB completadas
- [ ] Celery workers activos
- [ ] Modelos ML descargados y cargados

## Fase 11: Configuración Inicial de Aplicación

### Crear Usuario Admin

- [ ] Acceder a Web Server URL
- [ ] Crear primer usuario admin:
     ```bash
     curl -X POST https://<api-server-url>/api/admin/initial-user \
       -H "Content-Type: application/json" \
       -d '{"email": "admin@example.com", "password": "change-me"}'
     ```
- [ ] Login exitoso en la UI
- [ ] Dashboard accesible

### Configuración Básica

- [ ] Cambiar contraseña del admin
- [ ] Configurar conectores (si aplica)
- [ ] Probar búsqueda básica
- [ ] Probar chat con documentos de prueba

## Fase 12: Seguridad

- [ ] `AUTH_TYPE` cambiado a `basic` o `oidc` (no dejar en `disabled`)
- [ ] `ENCRYPTION_KEY_SECRET` es fuerte y único
- [ ] `VALID_EMAIL_DOMAINS` configurado para restringir signup
- [ ] Contraseñas de admin cambiadas
- [ ] Variables sensibles usando Railway Secrets
- [ ] Backups de PostgreSQL configurados
- [ ] Logs de acceso revisados

## Fase 13: Optimización

### Performance

- [ ] Recursos ajustados según uso real
- [ ] Auto-scaling configurado (si está disponible en tu plan)
- [ ] Cache (Redis) funcionando correctamente
- [ ] Vespa indexando correctamente

### Monitoreo

- [ ] Métricas de Railway revisadas
- [ ] Alertas configuradas (opcional)
- [ ] Logging funcionando
- [ ] Sentry integrado (opcional)

### Costos

- [ ] Estimación de costos mensual calculada
- [ ] Plan de Railway adecuado al uso esperado
- [ ] Recursos sobredimensionados identificados y ajustados

## Fase 14: CI/CD

- [ ] Auto-deploy desde GitHub configurado
- [ ] Rama de producción definida
- [ ] Estrategia de deploy definida (manual/automática)
- [ ] Rollback plan documentado

## Fase 15: Dominio Custom (Opcional)

- [ ] Dominio custom comprado
- [ ] DNS configurado en Railway
- [ ] SSL/TLS configurado automáticamente
- [ ] `WEB_DOMAIN` actualizado con dominio custom
- [ ] Redirect de dominio Railway a custom configurado

## Fase 16: Documentación

- [ ] URLs de servicios documentadas
- [ ] Credenciales guardadas en gestor de contraseñas
- [ ] Proceso de recuperación documentado
- [ ] Contactos de soporte definidos
- [ ] Runbook de incidentes creado

## Troubleshooting Common Issues

### Servicio no inicia

- [ ] Logs revisados: `railway logs -s <service-name>`
- [ ] Variables de entorno verificadas
- [ ] Dependencies verificadas
- [ ] Recursos suficientes asignados

### Error de conexión DB

- [ ] PostgreSQL está running
- [ ] Variables POSTGRES\_\* correctas
- [ ] Service Dependencies configuradas
- [ ] Network connectivity OK

### Model Server OOM

- [ ] RAM incrementada a 2GB+
- [ ] Considerar usar embeddings externos (OpenAI)
- [ ] Logs revisados para ver qué modelo causa OOM

### Background Worker no procesa

- [ ] Celery workers activos en logs
- [ ] Redis conectado correctamente
- [ ] API Server accesible desde worker
- [ ] Variables de entorno correctas

## Post-Deploy (Largo Plazo)

- [ ] Monitoreo continuo configurado
- [ ] Backup/restore process testeado
- [ ] Scaling strategy definida
- [ ] Costos monitoreados mensualmente
- [ ] Actualizaciones de seguridad aplicadas
- [ ] Onyx actualizado a última versión (cuando sea apropiado)

---

## Referencias

- [Railway Docs](https://docs.railway.app)
- [Onyx Deployment Docs](https://docs.onyx.app/deployment)
- [README de Despliegue](./README.md)

## Ayuda

Si encuentras problemas:

1. Revisa los logs: `railway logs -s <service-name>`
2. Verifica variables: `railway variables -s <service-name>`
3. Consulta la documentación de Railway
4. Abre un issue en el repo de Onyx

---

**Fecha de inicio:** ******\_******  
**Fecha de completación:** ******\_******  
**Responsable:** ******\_******  
**Revisado por:** ******\_******
