#!/bin/bash
# scripts/setup.sh - Configuración inicial simplificada
set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

main() {
    echo -e "${BLUE}=== October CMS Multi-Version Setup ===${NC}"
    echo ""

    # Verificar dependencias
    log "Verificando dependencias..."
    command -v docker >/dev/null 2>&1 || error "Docker no está instalado"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose no está instalado"
    docker info >/dev/null 2>&1 || error "Docker daemon no está funcionando"

    # Crear .env si no existe
    if [[ ! -f .env ]]; then
        log "Creando archivo .env..."
        cp env.example .env
    fi

    # Configurar hosts
    log "Verificando configuración de hosts..."
    if ! grep -q "v3.october.local" /etc/hosts 2>/dev/null; then
        warn "Los hosts no están configurados"
        echo ""
        echo "Agrega esta línea a /etc/hosts:"
        echo "127.0.0.1 v3.october.local v4.october.local"
        echo ""
        read -p "¿Deseas que lo configure automáticamente? (requiere sudo) [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "127.0.0.1 v3.october.local v4.october.local" | sudo tee -a /etc/hosts >/dev/null
            log "✓ Hosts configurados"
        fi
    else
        log "✓ Hosts ya configurados"
    fi

    # Dar permisos a scripts
    log "Configurando permisos..."
    find scripts/ -name "*.sh" -type f -exec chmod +x {} \;

    echo ""
    echo -e "${GREEN}=== Setup Completado ===${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. make up      # Iniciar servicios"
    echo "2. make install # Instalar October CMS"
    echo ""
    echo "URLs de acceso:"
    echo "  October v3.7: http://v3.october.local"
    echo "  October v4.0: http://v4.october.local"
    echo "  Adminer:      http://localhost:8080"
    echo "  MailHog:      http://localhost:8025"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@" 