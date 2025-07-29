#!/bin/bash
# setup.sh - Script inicial de configuración mejorado

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${GREEN}Configurando proyecto October CMS Multi-Version...${NC}"

# Verificar dependencias
log "Verificando dependencias..."
command -v docker >/dev/null 2>&1 || error "Docker no está instalado"
command -v docker-compose >/dev/null 2>&1 || error "Docker Compose no está instalado"

# Verificar versiones mínimas
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+' | head -1)

log "Docker: $DOCKER_VERSION, Compose: $COMPOSE_VERSION"

# Dar permisos de ejecución a todos los scripts
log "Configurando permisos..."
find . -name "*.sh" -type f -exec chmod +x {} \;

# Crear estructura de directorios
log "Creando directorios..."
mkdir -p data/{postgres,redis,nginx-logs,logs/{v3,v4},composer-{v3,v4},ssl}
mkdir -p v3/{october,config/{php,supervisor},scripts}
mkdir -p v4/{october,config/{php,supervisor},scripts}
mkdir -p shared/{nginx/sites,database,redis}

# Copiar archivos de ejemplo si no existen
log "Configurando archivos de entorno..."
[ ! -f "v3/.env" ] && [ -f "v3/.env.example" ] && cp v3/.env.example v3/.env
[ ! -f "v4/.env" ] && [ -f "v4/.env.example" ] && cp v4/.env.example v4/.env

# Verificar hosts
log "Verificando configuración hosts..."
if ! grep -q "v3.october.local" /etc/hosts 2>/dev/null; then
    warn "Agregar a /etc/hosts:"
    echo "127.0.0.1 v3.october.local v4.october.local"
fi

# Test básico de Docker
log "Verificando Docker..."
if ! docker info >/dev/null 2>&1; then
    error "Docker no está funcionando correctamente"
fi

echo ""
log "✅ Configuración completada"
echo ""
echo -e "${GREEN}Próximos pasos:${NC}"
echo "1. Agregar hosts: sudo echo '127.0.0.1 v3.october.local v4.october.local' >> /etc/hosts"
echo "2. Iniciar infraestructura: cd shared && ./manage-shared.sh start"
echo "3. Iniciar v3.7: cd ../v3 && ./manage-v3.sh start && ./manage-v3.sh install"
echo "4. Iniciar v4.0: cd ../v4 && ./manage-v4.sh start && ./manage-v4.sh install"
echo "5. Control maestro: ./master-control.sh start-all"