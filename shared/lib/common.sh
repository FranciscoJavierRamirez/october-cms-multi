# shared/lib/common.sh
#!/bin/bash

# Colores y logging unificados
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export BLUE='\033[0;34m'
export NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $1"; }

# Funciones comunes
wait_for_service() {
    local service=$1
    local port=$2
    local timeout=${3:-30}
    local counter=0
    
    while ! nc -z "$service" "$port" 2>/dev/null; do
        ((counter++))
        if [ $counter -gt $timeout ]; then
            return 1
        fi
        sleep 1
    done
    return 0
}

check_docker() {
    command -v docker >/dev/null 2>&1 || error "Docker no instalado"
    docker info >/dev/null 2>&1 || error "Docker daemon no está corriendo"
}

ensure_network() {
    docker network create october_shared_network 2>/dev/null || true
}