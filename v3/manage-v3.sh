#!/bin/bash
# manage-v3.sh - October CMS v3.7 simplificado
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
CONTAINER_NAME="october_v3_app"

# Colores básicos
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Verificar infraestructura compartida
check_shared() {
    if ! docker ps | grep -q "october_postgres_shared.*Up"; then
        error "Infraestructura compartida no está corriendo. Ejecuta: cd ../shared && ./manage-shared.sh start"
    fi
}

case "${1:-help}" in
    "start")
        log "Iniciando October CMS v3.7..."
        check_shared
        
        # Crear directorios
        mkdir -p october ../data/logs/v3
        
        # Iniciar container
        docker-compose -f "$COMPOSE_FILE" up -d
        
        # Esperar container
        log "Esperando container..."
        sleep 5
        
        if [[ ! -f "october/artisan" ]]; then
            log "October no instalado. Ejecuta: $0 install"
        fi
        
        log "✅ October v3.7 iniciado"
        echo "URL: http://v3.october.local"
        ;;
        
    "stop")
        log "Deteniendo October v3.7..."
        docker-compose -f "$COMPOSE_FILE" down
        log "✅ Detenido"
        ;;
        
    "install")
        log "Instalando October CMS v3.7..."
        check_shared
        
        # Verificar que el container esté corriendo
        docker ps | grep -q "$CONTAINER_NAME.*Up" || error "Container no está corriendo. Ejecuta: $0 start"
        
        # Instalar October
        log "Descargando October v3.7..."
        docker exec -w /var/www/html "$CONTAINER_NAME" \
            composer create-project october/october . "3.7.*" --prefer-dist --no-interaction
        
        # Configurar
        log "Configurando..."
        docker exec "$CONTAINER_NAME" bash -c "cat > .env << 'EOF'
APP_DEBUG=true
APP_URL=http://v3.october.local

DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=october_shared
DB_USERNAME=october_user
DB_PASSWORD=october_shared_2024
DB_PREFIX=v3_

REDIS_HOST=redis-shared
REDIS_PORT=6379

MAIL_HOST=mailhog-shared
MAIL_PORT=1025
EOF"
        
        # Generar key y migrar
        docker exec "$CONTAINER_NAME" php artisan key:generate
        docker exec "$CONTAINER_NAME" php artisan october:migrate
        
        # Crear admin
        log "Creando usuario admin..."
        docker exec "$CONTAINER_NAME" php artisan create:admin \
            --email="admin@localhost" --password="admin123" \
            --first-name="Admin" --last-name="User" || true
        
        log "✅ Instalación completa"
        echo ""
        echo "Accesos:"
        echo "  Frontend: http://v3.october.local"
        echo "  Backend:  http://v3.october.local/admin"
        echo "  Usuario:  admin@localhost"
        echo "  Password: admin123"
        ;;
        
    "artisan")
        shift
        docker exec -it "$CONTAINER_NAME" php artisan "$@"
        ;;
        
    "composer")
        shift
        docker exec -it "$CONTAINER_NAME" composer "$@"
        ;;
        
    "shell")
        docker exec -it "$CONTAINER_NAME" /bin/bash
        ;;
        
    "logs")
        docker-compose -f "$COMPOSE_FILE" logs -f
        ;;
        
    "status")
        echo -e "${BLUE}=== October CMS v3.7 ===${NC}"
        docker-compose -f "$COMPOSE_FILE" ps
        
        if docker ps | grep -q "$CONTAINER_NAME.*Up" && [[ -f "october/artisan" ]]; then
            echo ""
            docker exec "$CONTAINER_NAME" php artisan october:version || echo "Version no disponible"
        fi
        ;;
        
    *)
        echo "Uso: $0 {start|stop|install|status|logs|artisan|composer|shell}"
        echo ""
        echo "Comandos:"
        echo "  start       - Iniciar October v3.7"
        echo "  stop        - Detener October v3.7"
        echo "  install     - Instalar October CMS"
        echo "  status      - Ver estado"
        echo "  logs        - Ver logs"
        echo "  artisan ... - Ejecutar comando artisan"
        echo "  composer ...  - Ejecutar comando composer"
        echo "  shell       - Acceder al shell del container"
        echo ""
        echo "Ejemplo: $0 artisan make:plugin Acme.Blog"
        ;;
esac