#!/bin/bash
# manage-shared.sh - Infraestructura compartida simplificada
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# Colores básicos
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Verificar Docker
command -v docker >/dev/null 2>&1 || error "Docker no está instalado"

case "${1:-help}" in
    "start")
        log "Iniciando infraestructura compartida..."
        
        # Crear red si no existe
        docker network create october_shared_network 2>/dev/null || true
        
        # Crear directorios necesarios
        mkdir -p ../data/{postgres,redis,nginx-logs}
        
        # Iniciar servicios
        docker-compose -f "$COMPOSE_FILE" up -d
        
        # Esperar PostgreSQL
        log "Esperando PostgreSQL..."
        for i in {1..30}; do
            if docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared pg_isready -U october_user >/dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        log "✅ Infraestructura iniciada"
        echo ""
        echo "URLs de acceso:"
        echo "  PostgreSQL: localhost:5432"
        echo "  Redis:      localhost:6379"
        echo "  Adminer:    http://localhost:8080"
        echo "  MailHog:    http://localhost:8025"
        ;;
        
    "stop")
        log "Deteniendo infraestructura..."
        docker-compose -f "$COMPOSE_FILE" down
        log "✅ Infraestructura detenida"
        ;;
        
    "restart")
        $0 stop
        $0 start
        ;;
        
    "status")
        echo "=== Estado de servicios ==="
        docker-compose -f "$COMPOSE_FILE" ps
        ;;
        
    "logs")
        docker-compose -f "$COMPOSE_FILE" logs -f ${2:-}
        ;;
        
    "clean")
        read -p "¿Eliminar todos los datos? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose -f "$COMPOSE_FILE" down -v
            docker network rm october_shared_network 2>/dev/null || true
            rm -rf ../data/*
            log "✅ Limpieza completa"
        fi
        ;;
        
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|clean}"
        echo ""
        echo "Comandos:"
        echo "  start    - Iniciar servicios compartidos"
        echo "  stop     - Detener servicios"
        echo "  restart  - Reiniciar servicios"
        echo "  status   - Ver estado"
        echo "  logs     - Ver logs (opcional: nombre del servicio)"
        echo "  clean    - Limpiar todo (CUIDADO: borra datos)"
        ;;
esac