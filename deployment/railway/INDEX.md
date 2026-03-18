# 📚 Índice de Documentación - Despliegue en Railway

Esta carpeta contiene toda la documentación necesaria para desplegar Onyx en Railway.

## 📖 Guías Disponibles

### 1. 🚀 [QUICKSTART.md](./QUICKSTART.md)

**Para quién:** Usuarios experimentados con Railway que quieren desplegar rápido

**Contenido:**

- Setup en 10 minutos
- Comandos esenciales
- Checklist mínimo
- Troubleshooting rápido

**Tiempo estimado:** 1-1.5 horas

---

### 2. � [SERVICIOS_Y_VARIABLES.md](./SERVICIOS_Y_VARIABLES.md)

**Para quién:** Usuarios que necesitan configurar variables de entorno y puertos

**Contenido:**

- Variables de entorno completas por servicio (9 servicios)
- Puertos configurables y valores por defecto
- Ubicación exacta de Dockerfiles
- Configuración de build y deploy
- Comandos Railway para cada servicio
- Tablas resumen de puertos y Dockerfiles
- Diferencias entre build args y runtime vars

**Cuándo usar:** Durante la configuración inicial de servicios en Railway

---

### 3. �📘 [README.md](./README.md)

**Para quién:** Todos los usuarios, guía completa oficial

**Contenido:**

- Arquitectura del sistema
- Proceso de despliegue paso a paso (16 pasos)
- Configuración detallada de cada servicio
- Verificación del despliegue
- Monitoreo y troubleshooting
- Estimación de costos
- Seguridad
- Escalado
- Referencias

**Tiempo estimado:** 2-3 horas (primera vez)

---

### 4. ✅ [CHECKLIST.md](./CHECKLIST.md)

**Para quién:** Ingenieros que quieren seguir un proceso auditado

**Contenido:**

- 16 fases de despliegue
- 200+ items de verificación
- Pre-deploy checks
- Post-deploy validation
- Security checklist
- Optimization checklist
- Troubleshooting por problema común
- Post-deploy mantenimiento

**Uso:** Imprimir o usar como tracking en proyecto

---

### 5. 💎 [BEST_PRACTICES.md](./BEST_PRACTICES.md)

**Para quién:** Usuarios que quieren optimizar su despliegue

**Contenido:**

- Diagrama de arquitectura
- Optimizaciones de configuración
- Gestión de recursos y costos
- Networking avanzado
- Seguridad avanzada
- Monitoreo y observabilidad
- CI/CD best practices
- Backup y disaster recovery
- Scaling guidelines
- Troubleshooting detallado

**Cuándo leer:** Después del primer despliegue exitoso

---

### 6. ⚙️ [env.railway.template](./env.railway.template)

**Para quién:** Todos

**Contenido:**

- Template de variables de entorno
- Variables compartidas
- Variables por servicio
- Referencias entre servicios
- Comentarios explicativos
- Configuraciones opcionales
- Instrucciones de uso

**Uso:** Copiar y adaptar para tu despliegue

---

### 7. 🤖 [deploy.sh](./deploy.sh)

**Para quién:** Usuarios que prefieren CLI/automatización

**Contenido:**

- Script interactivo de despliegue
- Verificación de pre-requisitos
- Creación automática de servicios gestionados
- Configuración de variables
- Generación de encryption keys
- Guardado de información del deployment

**Uso:**

```bash
cd deployment/railway
./deploy.sh
```

---

### 8. 📊 [EXECUTIVE_SUMMARY.md](./EXECUTIVE_SUMMARY.md)

**Para quién:** Managers, CTOs, decision-makers no técnicos

**Contenido:**

- Resumen ejecutivo del despliegue
- Análisis de costos detallado ($81-220/mes)
- Comparación con alternativas (AWS, GCP, Azure)
- Pros y contras de Railway
- Recomendaciones de configuración
- Timeline de implementación
- KPIs de éxito

**Cuándo leer:** Antes de aprobar el despliegue o para presentar a stakeholders

---

## 🎯 ¿Por Dónde Empezar?

### Si eres nuevo en Railway:

1. Lee [README.md](./README.md) completo
2. Sigue el [CHECKLIST.md](./CHECKLIST.md) paso a paso
3. Usa [env.railway.template](./env.railway.template) para configuración
4. Luego optimiza con [BEST_PRACTICES.md](./BEST_PRACTICES.md)

### Si ya conoces Railway:

1. Lee [QUICKSTART.md](./QUICKSTART.md)
2. Consulta [SERVICIOS_Y_VARIABLES.md](./SERVICIOS_Y_VARIABLES.md) para configurar cada servicio
3. Ejecuta [deploy.sh](./deploy.sh)
4. Consulta [CHECKLIST.md](./CHECKLIST.md) para validación
5. Optimiza con [BEST_PRACTICES.md](./BEST_PRACTICES.md)

### Si necesitas configurar variables de entorno:

1. Abre [SERVICIOS_Y_VARIABLES.md](./SERVICIOS_Y_VARIABLES.md) - guía completa por servicio
2. Usa [env.railway.template](./env.railway.template) como referencia
3. Configura variables en Railway siguiendo los comandos del documento

### Si eres Manager/CTO/Decision-maker:

1. Lee [EXECUTIVE_SUMMARY.md](./EXECUTIVE_SUMMARY.md) para análisis de costos y decisión
2. Revisa la arquitectura en [INDEX.md](./INDEX.md)
3. Delega la implementación usando [README.md](./README.md) o [CHECKLIST.md](./CHECKLIST.md)

### Si ya tienes un deployment:

1. Revisa [BEST_PRACTICES.md](./BEST_PRACTICES.md) para optimizaciones
2. Usa [CHECKLIST.md](./CHECKLIST.md) sección "Post-Deploy"
3. Implementa mejoras de seguridad y monitoreo

---

## 📊 Comparación de Guías

| Característica | QUICKSTART | SERVICIOS_VARS | README | CHECKLIST | BEST_PRACTICES |
| --- | --- | --- | --- | --- | --- |
| Tiempo de lectura | 5 min | 15 min | 30 min | 45 min | 60 min |
| Nivel de detalle | Básico | Técnico | Completo | Exhaustivo | Avanzado |
| Formato | Comandos | Referencia | Paso a paso | Lista verificación | Tips & tricks |
| Para producción | ⚠️ Mínimo | ✅ Esencial | ✅ Completo | ✅ Auditado | ✅ Optimizado |
| Incluye troubleshooting | Básico | N/A | Medio | Alto | Muy alto |

---

## 🗂️ Estructura de Archivos

```
deployment/railway/
├── README.md                   # Guía principal completa
├── QUICKSTART.md               # Guía rápida (10 min)
├── SERVICIOS_Y_VARIABLES.md    # Envs, puertos y Dockerfiles por servicio
├── CHECKLIST.md                # Lista de verificación completa
├── BEST_PRACTICES.md           # Optimizaciones y mejores prácticas
├── EXECUTIVE_SUMMARY.md        # Resumen para decision-makers
├── INDEX.md                    # Este archivo (índice)
├── env.railway.template        # Template de variables de entorno
├── deploy.sh                   # Script de deployment automatizado
└── deployment-info.txt         # (se genera después del deploy)
```

---

## 🏗️ Arquitectura del Sistema

### Servicios Principales

```
┌─────────────────────────────────────────────────────────────┐
│                       Railway Project                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  PostgreSQL  │  │    Redis     │  │    MinIO     │      │
│  │  (Managed)   │  │  (Managed)   │  │  (Custom)    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         │       ┌──────────┴──────────┐       │              │
│         │       │                     │       │              │
│         │  ┌────▼────┐           ┌───▼───┐   │              │
│         │  │  Vespa  │           │ Model │   │              │
│         │  │ (Index) │           │Servers│   │              │
│         │  └────┬────┘           └───┬───┘   │              │
│         │       │                    │       │              │
│  ┌──────┴───────┴────────────────────┴───────┴──────────┐   │
│  │                                                        │   │
│  │  ┌─────────────┐         ┌──────────────┐           │   │
│  │  │ API Server  │◀────────│  Background  │           │   │
│  │  │   :8080     │         │    Worker    │           │   │
│  │  └──────┬──────┘         └──────────────┘           │   │
│  │         │                                            │   │
│  └─────────┼────────────────────────────────────────────┘   │
│            │                                                 │
│   ┌────────▼────────┐                                       │
│   │   Web Server    │                                       │
│   │   (Frontend)    │                                       │
│   └────────┬────────┘                                       │
│            │                                                 │
└────────────┼─────────────────────────────────────────────────┘
             │
      Railway Edge
       (SSL/CDN)
             │
        ┌────▼────┐
        │  Users  │
        └─────────┘
```

### Flujo de Datos

1. **Usuario → Web Server** (port 3000)
2. **Web Server → API Server** (internal, port 8080)
3. **API Server → PostgreSQL** (lectura/escritura)
4. **API Server → Redis** (cache, queues)
5. **API Server → MinIO** (almacenamiento de archivos)
6. **API Server → Vespa** (búsqueda vectorial)
7. **API Server → Model Servers** (embeddings)
8. **Background Worker → Todos** (procesamiento asíncrono)

---

## 💡 Tips por Experiencia

### Primera vez usando Railway

- Tiempo estimado: 3-4 horas
- Usa README.md + CHECKLIST.md
- Tómate tu tiempo en la configuración de variables
- Verifica cada servicio antes de continuar

### Ya tienes experiencia con Railway

- Tiempo estimado: 1-1.5 horas
- Usa QUICKSTART.md
- Ejecuta deploy.sh
- Valida con CHECKLIST.md (sección crítica)

### Migrando de otro proveedor

- Lee BEST_PRACTICES.md primero
- Entiende las diferencias de Railway
- Planifica migración de datos
- Usa staging environment primero

### Deployment en producción crítica

- Usa CHECKLIST.md completo
- Implementa TODO en BEST_PRACTICES.md
- Configura monitoreo completo
- Ten disaster recovery plan
- Considera Professional Services

---

## 🎓 Recursos Adicionales

### Documentación Externa

- [Railway Documentation](https://docs.railway.app)
- [Railway Templates](https://railway.app/templates)
- [Railway Blog](https://blog.railway.app)
- [Railway Discord](https://discord.gg/railway)

### Onyx Documentation

- [Onyx Docs](https://docs.onyx.app)
- [Onyx GitHub](https://github.com/onyx-dot-app/onyx)
- [Deployment Guide General](https://docs.onyx.app/deployment)

### Community

- [Onyx Discord](https://discord.gg/onyx)
- [Railway Community](https://community.railway.app)

---

## 🆘 Soporte

### Durante el Deployment

1. **Verifica documentación local primero**
     - README.md troubleshooting section
     - BEST_PRACTICES.md issue específico
     - CHECKLIST.md validaciones

2. **Revisa logs**

     ```bash
     railway logs -s <servicio>
     ```

3. **Verifica Railway status**
     - [Railway Status](https://status.railway.app)

4. **Busca en Railway Discord**
     - Canal #help
     - Busca problemas similares

5. **Abre ticket de soporte**
     - Railway: support@railway.app
     - Onyx: Discord o GitHub Issues

### Issues Comunes y Soluciones Rápidas

| Issue              | Solución Rápida          | Documentación                      |
| ------------------ | ------------------------ | ---------------------------------- |
| OOM                | Incrementar RAM          | BEST_PRACTICES.md #troubleshooting |
| Connection refused | Verificar PRIVATE_DOMAIN | BEST_PRACTICES.md #networking      |
| Slow startup       | Ver health checks        | README.md #verificacion            |
| High costs         | Optimizar recursos       | BEST_PRACTICES.md #costos          |
| Deployment timeout | Verificar dependencies   | README.md #paso-9                  |

---

## 📅 Roadmap de Deployment

### Semana 1: Setup Inicial

- [ ] Día 1: Lectura de documentación
- [ ] Día 2-3: Deploy básico siguiendo README.md
- [ ] Día 4: Verificación completa con CHECKLIST.md
- [ ] Día 5: Testing y QA

### Semana 2: Optimización

- [ ] Día 1-2: Implementar BEST_PRACTICES.md
- [ ] Día 3: Configurar monitoreo
- [ ] Día 4: Configurar backups
- [ ] Día 5: Documentar runbooks

### Semana 3: Producción

- [ ] Día 1: Configurar autenticación (AUTH_TYPE)
- [ ] Día 2: Configurar dominio custom
- [ ] Día 3: Testing de carga
- [ ] Día 4: Go-live
- [ ] Día 5: Monitoreo post-launch

### Continuo: Mantenimiento

- Semanal: Revisar métricas
- Mensual: Revisar costos
- Trimestral: Actualizar Onyx
- Anual: Disaster recovery drill

---

## ✨ Notas Finales

- Esta documentación está diseñada para ser completa pero accesible
- Empieza con lo básico y ve profundizando según necesites
- No todos los pasos son obligatorios, adapta a tu caso
- La seguridad y monitoreo son críticos para producción
- Railway facilita mucho el deployment, aprovéchalo

**¡Buena suerte con tu deployment!** 🚀

---

**Última actualización:** 2026-03-18  
**Versión:** 1.0  
**Mantenido por:** Equipo Onyx
