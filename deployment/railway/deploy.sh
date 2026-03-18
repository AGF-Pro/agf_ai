#!/bin/bash

# 🚂 Script de Despliegue Automatizado en Railway
# Este script te guía paso a paso en el despliegue de Onyx en Railway

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 no está instalado"
        return 1
    fi
    print_success "$1 está instalado"
    return 0
}

# Welcome
clear
echo -e "${BLUE}"
cat << "EOF"
   ____                     
  / __ \____  __  ___  __
 / / / / __ \/ / / / |/_/
/ /_/ / / / / /_/ />  <  
\____/_/ /_/\__, /_/|_|  
           /____/         
   Deployment to Railway
EOF
echo -e "${NC}"

print_header "PASO 1: Verificación de Pre-requisitos"

# Check Railway CLI
if ! check_command "railway"; then
    print_warning "Railway CLI no está instalado. Instalando..."
    npm install -g @railway/cli
    if [ $? -eq 0 ]; then
        print_success "Railway CLI instalado correctamente"
    else
        print_error "Error instalando Railway CLI. Por favor, instala manualmente:"
        echo "  npm i -g @railway/cli"
        exit 1
    fi
fi

# Check if logged in to Railway
print_info "Verificando autenticación en Railway..."
if ! railway whoami &> /dev/null; then
    print_warning "No estás autenticado en Railway. Iniciando login..."
    railway login
    if [ $? -ne 0 ]; then
        print_error "Error en el login. Por favor, intenta: railway login"
        exit 1
    fi
fi
print_success "Autenticado en Railway correctamente"

# Check Docker
if ! check_command "docker"; then
    print_error "Docker no está instalado. Por favor, instálalo desde https://docker.com"
    exit 1
fi

# Check Git
if ! check_command "git"; then
    print_error "Git no está instalado. Por favor, instálalo"
    exit 1
fi

print_header "PASO 2: Configuración del Proyecto"

# Ask for project details
read -p "Nombre del proyecto en Railway (default: onyx-production): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-onyx-production}

read -p "¿Crear nuevo proyecto? (s/n, default: s): " CREATE_PROJECT
CREATE_PROJECT=${CREATE_PROJECT:-s}

if [ "$CREATE_PROJECT" = "s" ]; then
    print_info "Creando proyecto en Railway..."
    railway init -n "$PROJECT_NAME"
    if [ $? -ne 0 ]; then
        print_error "Error creando proyecto. ¿Ya existe?"
        read -p "¿Quieres vincularte a un proyecto existente? (s/n): " LINK_EXISTING
        if [ "$LINK_EXISTING" = "s" ]; then
            railway link
        else
            exit 1
        fi
    else
        print_success "Proyecto '$PROJECT_NAME' creado"
    fi
else
    print_info "Vinculándote a proyecto existente..."
    railway link
fi

print_header "PASO 3: Configuración de Variables de Entorno"

# Generate encryption key
print_info "Generando ENCRYPTION_KEY_SECRET..."
ENCRYPTION_KEY=$(openssl rand -base64 32)
print_success "Clave generada"

# Ask for OpenAI API Key
read -p "API Key de OpenAI (requerida): " OPENAI_API_KEY
while [ -z "$OPENAI_API_KEY" ]; do
    print_warning "La API Key de OpenAI es obligatoria"
    read -p "API Key de OpenAI: " OPENAI_API_KEY
done

# Ask for other configurations
read -p "Modelo GPT a usar (default: gpt-4): " GPT_MODEL
GPT_MODEL=${GPT_MODEL:-gpt-4}

read -p "Modelo GPT rápido (default: gpt-3.5-turbo): " GPT_FAST_MODEL
GPT_FAST_MODEL=${GPT_FAST_MODEL:-gpt-3.5-turbo}

read -p "Dominios de email permitidos (opcional, separados por coma): " VALID_EMAIL_DOMAINS

print_info "Configurando variables de entorno compartidas..."

# Set shared variables
railway variables set \
    AUTH_TYPE=disabled \
    ENCRYPTION_KEY_SECRET="$ENCRYPTION_KEY" \
    GEN_AI_MODEL_PROVIDER=openai \
    GEN_AI_MODEL_VERSION="$GPT_MODEL" \
    FAST_GEN_AI_MODEL_VERSION="$GPT_FAST_MODEL" \
    OPENAI_API_KEY="$OPENAI_API_KEY" \
    ENABLE_PAID_ENTERPRISE_EDITION_FEATURES=false \
    USE_LIGHTWEIGHT_BACKGROUND_WORKER=true \
    FILE_STORE_BACKEND=s3 \
    S3_AWS_ACCESS_KEY_ID=minioadmin \
    S3_AWS_SECRET_ACCESS_KEY=minioadmin \
    S3_FILE_STORE_BUCKET_NAME=onyx-file-store-bucket \
    LOG_LEVEL=info \
    DISABLE_TELEMETRY=true

if [ ! -z "$VALID_EMAIL_DOMAINS" ]; then
    railway variables set VALID_EMAIL_DOMAINS="$VALID_EMAIL_DOMAINS"
fi

print_success "Variables de entorno configuradas"

print_header "PASO 4: Creación de Servicios Gestionados"

# PostgreSQL
print_info "Creando servicio PostgreSQL..."
railway add --database postgres
if [ $? -eq 0 ]; then
    print_success "PostgreSQL creado"
else
    print_warning "PostgreSQL ya existe o hubo un error"
fi

# Redis
print_info "Creando servicio Redis..."
railway add --database redis
if [ $? -eq 0 ]; then
    print_success "Redis creado"
else
    print_warning "Redis ya existe o hubo un error"
fi

print_header "PASO 5: Creación de Servicios Containerizados"

print_warning "Los siguientes servicios deben crearse manualmente desde la UI de Railway:"
echo ""
echo "1. Vespa (Motor de búsqueda vectorial)"
echo "   - Image: vespaengine/vespa:8.609.39"
echo "   - Port: 8081"
echo "   - Volume: /opt/vespa/var (10GB)"
echo ""
echo "2. MinIO (Almacenamiento S3)"
echo "   - Image: minio/minio:RELEASE.2025-07-23T15-54-02Z-cpuv1"
echo "   - Port: 9000"
echo "   - Volume: /data (20GB)"
echo "   - Start Command: server /data --console-address :9001"
echo "   - Vars: MINIO_ROOT_USER=minioadmin MINIO_ROOT_PASSWORD=minioadmin"
echo "   - Vars: MINIO_DEFAULT_BUCKETS=onyx-file-store-bucket"
echo ""
echo "3. Model Server - Inference"
echo "   - Source: GitHub (este repo)"
echo "   - Root: backend"
echo "   - Dockerfile: Dockerfile.model_server"
echo "   - Port: 8080"
echo "   - Volume: /app/.cache/huggingface/ (5GB)"
echo ""
echo "3. Model Server - Indexing"
echo "3. Model Server - Inference"
echo "   - Source: GitHub (este repo)"
echo "   - Root: backend"
echo "   - Dockerfile: Dockerfile.model_server"
echo "   - Port: 8080"
echo "   - Volume: /app/.cache/huggingface/ (5GB)"
echo ""
echo "4. Model Server - Indexing"
echo "   - Source: GitHub (este repo)"
echo "   - Root: backend"
echo "   - Dockerfile: Dockerfile.model_server"
echo "   - Port: 8080"
echo "   - Volume: /app/.cache/huggingface/ (5GB)"
echo "   - Vars adicionales: INDEXING_ONLY=true"
echo ""
echo "5. API Server"
echo "   - Source: GitHub (este repo)"
echo "   - Root: backend"
echo "   - Dockerfile: Dockerfile"
echo "   - Port: 8080"
echo "   - Habilitar Public Networking"
echo "   - NO necesita volumen (MinIO maneja storage)"
echo ""
echo "6. Background Worker"
echo "   - Source: GitHub (este repo)"
echo "   - Root: backend"
echo "   - Dockerfile: Dockerfile"
echo "   - Start: /app/scripts/supervisord_entrypoint.sh"
echo "   - NO public networking"
echo ""
echo "7. Web Server"
echo "   - Source: GitHub (este repo)"
echo "   - Root: web"
echo "   - Dockerfile: Dockerfile"
echo "   - Port: 3000"
echo "   - Habilitar Public Networking"
echo ""

print_info "Presiona Enter cuando hayas completado la creación de servicios en la UI..."
read

print_header "PASO 6: Verificación del Despliegue"

print_info "Verificando estado de los servicios..."
railway status

print_header "PASO 7: Información de Acceso"

echo ""
print_success "🎉 Despliegue completado!"
echo ""
print_info "Información importante guardada en:"
echo "  - Variables de entorno: railway variables"
echo "  - Estado de servicios: railway status"
echo "  - Logs: railway logs"
echo ""
print_warning "PRÓXIMOS PASOS:"
echo "  1. Espera a que todos los servicios estén 'Running'"
echo "  2. Accede a la URL del web-server (railway domain)"
echo "  3. Crea tu primer usuario admin"
echo "  4. Cambia AUTH_TYPE a 'basic' o 'oidc' para producción"
echo ""
print_info "Para ver la URL del web-server:"
echo "  railway service web-server"
echo ""
print_info "Para ver logs en tiempo real:"
echo "  railway logs -f"
echo ""

# Save deployment info
DEPLOYMENT_INFO_FILE="deployment/railway/deployment-info.txt"
mkdir -p "deployment/railway"
cat > "$DEPLOYMENT_INFO_FILE" << EOF
Onyx Deployment on Railway
==========================
Project: $PROJECT_NAME
Date: $(date)

Encryption Key: $ENCRYPTION_KEY

Services Created:
- PostgreSQL (managed)
- Redis (managed)
- Vespa
- Model Server (Inference)
- Model Server (Indexing)
- API Server
- Background Worker
- Web Server

Next Steps:
1. Verify all services are running: railway status
2. Get web server URL: railway service web-server
3. Create admin user
4. Configure authentication (AUTH_TYPE)

For more info, see: deployment/railway/README.md
EOF

print_success "Información del despliegue guardada en: $DEPLOYMENT_INFO_FILE"

print_info "¿Quieres abrir el proyecto en Railway? (s/n)"
read -p "> " OPEN_RAILWAY
if [ "$OPEN_RAILWAY" = "s" ]; then
    railway open
fi

echo ""
print_success "✨ Despliegue completado. ¡Buena suerte!"
