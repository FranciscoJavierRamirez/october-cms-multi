#!/bin/bash
# manage-v4.sh - October CMS v4.0 simplificado
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
CONTAINER_NAME="october_v4_app"

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
        log "Iniciando October CMS v4.0..."
        check_shared
        
        # Crear directorios
        mkdir -p october ../data/logs/v4
        
        # Iniciar container
        docker-compose -f "$COMPOSE_FILE" up -d
        
        # Esperar container
        log "Esperando container..."
        sleep 5
        
        if [[ ! -f "october/artisan" ]]; then
            log "October no instalado. Ejecuta: $0 install"
        fi
        
        log "✅ October v4.0 iniciado"
        echo "URL: http://v4.october.local"
        ;;
        
    "stop")
        log "Deteniendo October v4.0..."
        docker-compose -f "$COMPOSE_FILE" down
        log "✅ Detenido"
        ;;
        
    "install")
        log "Instalando October CMS v4.0..."
        check_shared
        
        # Verificar que el container esté corriendo
        docker ps | grep -q "$CONTAINER_NAME.*Up" || error "Container no está corriendo. Ejecuta: $0 start"
        
        # Instalar October
        log "Descargando October v4.0..."
        docker exec -w /var/www/html "$CONTAINER_NAME" \
            composer create-project october/october . "4.0.*" --prefer-dist --no-interaction
        
        # Configurar
        log "Configurando..."
        docker exec "$CONTAINER_NAME" bash -c "cat > .env << 'EOF'
APP_DEBUG=true
APP_URL=http://v4.october.local

DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=october_shared
DB_USERNAME=october_user
DB_PASSWORD=october_shared_2024
DB_PREFIX=v4_

REDIS_HOST=redis-shared
REDIS_PORT=6379
REDIS_DATABASE=1

MAIL_HOST=mailhog-shared
MAIL_PORT=1025

# October v4.0 features
NEW_DASHBOARD_ENABLED=true
EOF"
        
        # Generar key y migrar
        docker exec "$CONTAINER_NAME" php artisan key:generate
        docker exec "$CONTAINER_NAME" php artisan october:migrate
        
        # Crear admin
        log "Creando usuario admin..."
        docker exec "$CONTAINER_NAME" php artisan create:admin \
            --email="admin@localhost" --password="admin123" \
            --first-name="Admin" --last-name="User" || true
        
        # Optimizaciones Laravel 12
        log "Aplicando optimizaciones..."
        docker exec "$CONTAINER_NAME" php artisan config:cache || true
        docker exec "$CONTAINER_NAME" php artisan route:cache || true
        
        log "✅ Instalación completa"
        echo ""
        echo "Accesos:"
        echo "  Frontend: http://v4.october.local"
        echo "  Backend:  http://v4.october.local/admin"
        echo "  Usuario:  admin@localhost"
        echo "  Password: admin123"
        ;;
        
    "optimize")
        log "Optimizando October v4.0..."
        docker exec "$CONTAINER_NAME" php artisan config:cache
        docker exec "$CONTAINER_NAME" php artisan route:cache
        docker exec "$CONTAINER_NAME" php artisan view:cache
        log "✅ Optimizado"
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
        echo -e "${BLUE}=== October CMS v4.0 ===${NC}"
        docker-compose -f "$COMPOSE_FILE" ps
        
        if docker ps | grep -q "$CONTAINER_NAME.*Up" && [[ -f "october/artisan" ]]; then
            echo ""
            docker exec "$CONTAINER_NAME" php artisan october:version || echo "Version no disponible"
            echo "Laravel: $(docker exec "$CONTAINER_NAME" php artisan --version 2>/dev/null | head -1)"
            echo "PHP: $(docker exec "$CONTAINER_NAME" php -v | head -1)"
        fi
        ;;
        
    *)
        echo "Uso: $0 {start|stop|install|status|logs|optimize|artisan|composer|shell}"
        echo ""
        echo "Comandos:"
        echo "  start       - Iniciar October v4.0"
        echo "  stop        - Detener October v4.0"
        echo "  install     - Instalar October CMS"
        echo "  status      - Ver estado"
        echo "  logs        - Ver logs"
        echo "  optimize    - Optimizar para producción"
        echo "  artisan ... - Ejecutar comando artisan"
        echo "  composer ...  - Ejecutar comando composer"
        echo "  shell       - Acceder al shell del container"
        echo ""
        echo "Ejemplo: $0 artisan make:plugin Acme.Blog"
        ;;
esac