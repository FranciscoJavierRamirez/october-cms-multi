#!/bin/bash
# master-control.sh - Control maestro para October CMS multi-versión
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }

case "${1:-help}" in
    "start-all")
        log "Iniciando todo el sistema..."
        cd "$SCRIPT_DIR/shared" && ./manage-shared.sh start
        cd "$SCRIPT_DIR/v3" && ./manage-v3.sh start
        cd "$SCRIPT_DIR/v4" && ./manage-v4.sh start
        
        echo ""
        echo -e "${BLUE}=== Sistema completo iniciado ===${NC}"
        echo "October v3.7: http://v3.october.local"
        echo "October v4.0: http://v4.october.local"
        echo "Adminer:      http://localhost:8080"
        echo "MailHog:      http://localhost:8025"
        ;;
        
    "stop-all")
        log "Deteniendo todo el sistema..."
        cd "$SCRIPT_DIR/v3" && ./manage-v3.sh stop
        cd "$SCRIPT_DIR/v4" && ./manage-v4.sh stop
        cd "$SCRIPT_DIR/shared" && ./manage-shared.sh stop
        log "✅ Sistema detenido"
        ;;
        
    "status")
        echo -e "${BLUE}=== Estado del Sistema ===${NC}"
        echo ""
        echo "INFRAESTRUCTURA COMPARTIDA:"
        cd "$SCRIPT_DIR/shared" && ./manage-shared.sh status
        echo ""
        echo "OCTOBER v3.7:"
        cd "$SCRIPT_DIR/v3" && ./manage-v3.sh status
        echo ""
        echo "OCTOBER v4.0:"
        cd "$SCRIPT_DIR/v4" && ./manage-v4.sh status
        ;;
        
    "install-all")
        log "Instalando ambas versiones de October..."
        cd "$SCRIPT_DIR/v3" && ./manage-v3.sh install
        cd "$SCRIPT_DIR/v4" && ./manage-v4.sh install
        log "✅ Ambas versiones instaladas"
        ;;
        
    *)
        echo -e "${BLUE}October CMS Multi-Version Control${NC}"
        echo ""
        echo "Uso: $0 {start-all|stop-all|status|install-all}"
        echo ""
        echo "Comandos:"
        echo "  start-all    - Iniciar todo (infra + v3.7 + v4.0)"
        echo "  stop-all     - Detener todo"
        echo "  status       - Ver estado completo"
        echo "  install-all  - Instalar ambas versiones"
        echo ""
        echo "Para control individual:"
        echo "  ./shared/manage-shared.sh {start|stop|status}"
        echo "  ./v3/manage-v3.sh {start|stop|install|status}"
        echo "  ./v4/manage-v4.sh {start|stop|install|status}"
        ;;
esac