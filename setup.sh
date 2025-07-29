#!/bin/bash
# setup-improved.sh - Script mejorado de configuración inicial

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}=== October CMS Multi-Version Setup ===${NC}"
echo ""

# Verificar sistema operativo
OS=$(uname -s)
log "Sistema detectado: $OS"

# Verificar dependencias
log "Verificando dependencias..."
command -v docker >/dev/null 2>&1 || error "Docker no está instalado. Visita: https://docs.docker.com/install/"
command -v docker-compose >/dev/null 2>&1 || error "Docker Compose no está instalado"

# Verificar versiones mínimas
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+' | head -1)

DOCKER_MIN_VERSION="20.0"
COMPOSE_MIN_VERSION="2.0"

version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if ! version_ge "$DOCKER_VERSION" "$DOCKER_MIN_VERSION"; then
    error "Docker $DOCKER_VERSION es muy antiguo. Se requiere $DOCKER_MIN_VERSION+"
fi

if ! version_ge "$COMPOSE_VERSION" "$COMPOSE_MIN_VERSION"; then
    warn "Docker Compose $COMPOSE_VERSION puede ser antiguo. Se recomienda $COMPOSE_MIN_VERSION+"
fi

log "Docker: $DOCKER_VERSION ✓, Compose: $COMPOSE_VERSION ✓"

# Verificar que Docker esté funcionando
log "Verificando Docker daemon..."
if ! docker info >/dev/null 2>&1; then
    error "Docker no está funcionando. Inicia Docker Desktop o el servicio Docker"
fi

# Crear estructura de directorios
log "Creando estructura de directorios..."
mkdir -p data/{postgres,redis,nginx-logs,logs/{v3,v4},composer-{v3,v4},ssl}
mkdir -p v3/{october,config/{php,supervisor},scripts}
mkdir -p v4/{october,config/{php,supervisor},scripts}
mkdir -p shared/{nginx/sites,database,redis}

# Dar permisos de ejecución a scripts
log "Configurando permisos de scripts..."
find . -name "*.sh" -type f -exec chmod +x {} \;

# Copiar archivos de ejemplo si no existen
log "Configurando archivos de entorno..."
[ ! -f "v3/.env" ] && [ -f "v3/.env.example" ] && cp v3/.env.example v3/.env && log "✓ v3/.env creado"
[ ! -f "v4/.env" ] && [ -f "v4/.env.example" ] && cp v4/.env.example v4/.env && log "✓ v4/.env creado"

# Verificar y configurar hosts
log "Verificando configuración de hosts..."
HOSTS_CONFIGURED=false

if [[ "$OS" == "Darwin" ]] || [[ "$OS" == "Linux" ]]; then
    if ! grep -q "v3.october.local" /etc/hosts 2>/dev/null; then
        warn "Los hosts no están configurados"
        echo ""
        echo "Agrega las siguientes líneas a /etc/hosts:"
        echo "127.0.0.1 v3.october.local v4.october.local"
        echo ""
        read -p "¿Deseas que lo haga automáticamente? (requiere sudo) [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "127.0.0.1 v3.october.local v4.october.local" | sudo tee -a /etc/hosts >/dev/null
            log "✓ Hosts configurados"
            HOSTS_CONFIGURED=true
        fi
    else
        log "✓ Hosts ya configurados"
        HOSTS_CONFIGURED=true
    fi
fi

# Crear red Docker si no existe
log "Configurando red Docker..."
if ! docker network ls | grep -q "october_shared_network"; then
    docker network create october_shared_network --subnet=172.30.0.0/16
    log "✓ Red Docker creada"
else
    log "✓ Red Docker ya existe"
fi

# Validar espacio en disco
log "Verificando espacio en disco..."
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ "$AVAILABLE_SPACE" =~ ^[0-9]+$ ]] && [ "$AVAILABLE_SPACE" -lt 10 ]; then
    warn "Espacio disponible: ${AVAILABLE_SPACE}GB. Se recomiendan al menos 10GB"
fi

# Resumen final
echo ""
echo -e "${GREEN}=== Configuración Completada ===${NC}"
echo ""
echo -e "${BLUE}Estado del sistema:${NC}"
echo "✓ Docker $DOCKER_VERSION"
echo "✓ Docker Compose $COMPOSE_VERSION"
echo "✓ Estructura de directorios creada"
echo "✓ Permisos configurados"
echo "✓ Red Docker disponible"
if [ "$HOSTS_CONFIGURED" = true ]; then
    echo "✓ Hosts configurados"
else
    echo "⚠ Hosts pendientes de configurar"
fi

echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo ""
if [ "$HOSTS_CONFIGURED" = false ]; then
    echo "1. Configurar hosts:"
    echo "   sudo echo '127.0.0.1 v3.october.local v4.october.local' >> /etc/hosts"
    echo ""
fi
echo "2. Iniciar todo el sistema:"
echo "   ./master-control.sh start-all"
echo ""
echo "3. Instalar October CMS:"
echo "   ./master-control.sh install-all"
echo ""
echo "4. Acceder a las aplicaciones:"
echo "   - October v3.7: http://v3.october.local"
echo "   - October v4.0: http://v4.october.local"
echo "   - Adminer: http://localhost:8080"
echo "   - MailHog: http://localhost:8025"
echo ""
echo -e "${GREEN}¡Listo para comenzar!${NC}"