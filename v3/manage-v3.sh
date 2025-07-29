#!/bin/bash

# manage-v3.sh
# Gestión de October CMS v3.7 independiente
# Autor: framirez@healthytek.cl
# Versión: 1.0

set -euo pipefail

# ============================================
# CONFIGURACIÓN Y VARIABLES
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DIR="$PROJECT_ROOT/shared"
DATA_DIR="$PROJECT_ROOT/data"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
ENV_FILE="$SCRIPT_DIR/.env"

# Información de October v3.7
OCTOBER_VERSION="3.7"
LARAVEL_VERSION="10"
PHP_VERSION="8.1"
CONTAINER_NAME="october_v3_app"
DOMAIN="v3.october.local"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorios
OCTOBER_DIR="$SCRIPT_DIR/october"
LOGS_DIR="$DATA_DIR/logs/v3"
COMPOSER_CACHE="$DATA_DIR/composer-v3"
BACKUP_DIR="$DATA_DIR/backups/v3"

# ============================================
# FUNCIONES AUXILIARES
# ============================================

print_banner() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                🎃 OCTOBER CMS v3.7 MANAGER                   ║"
    echo "║               Laravel 10 + PHP 8.1 + Builder                 ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

check_dependencies() {
    log_info "Verificando dependencias..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose no está instalado"
        exit 1
    fi
    
    # Verificar infraestructura compartida
    check_shared_infrastructure
    
    log_info "✅ Dependencias verificadas"
}

check_shared_infrastructure() {
    log_info "Verificando infraestructura compartida..."
    
    # Verificar red Docker
    if ! docker network ls | grep -q "october_shared_network"; then
        log_error "Red 'october_shared_network' no existe"
        log_warn "Ejecuta primero: $SHARED_DIR/manage-shared.sh start"
        exit 1
    fi
    
    # Verificar PostgreSQL
    if ! docker ps | grep -q "october_postgres_shared.*Up"; then
        log_error "PostgreSQL compartido no está corriendo"
        log_warn "Ejecuta: $SHARED_DIR/manage-shared.sh start"
        exit 1
    fi
    
    # Verificar Redis
    if ! docker ps | grep -q "october_redis_shared.*Up"; then
        log_error "Redis compartido no está corriendo"
        log_warn "Ejecuta: $SHARED_DIR/manage-shared.sh start"
        exit 1
    fi
    
    log_info "✅ Infraestructura compartida verificada"
}

create_directories() {
    log_info "Creando estructura de directorios..."
    
    local dirs=(
        "$OCTOBER_DIR"
        "$LOGS_DIR"
        "$COMPOSER_CACHE"
        "$BACKUP_DIR"
        "$SCRIPT_DIR/config/php"
        "$SCRIPT_DIR/config/supervisor"
        "$SCRIPT_DIR/scripts"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "Creado: $dir"
        fi
    done
    
    # Permisos correctos para October
    chmod -R 755 "$OCTOBER_DIR"
    chmod -R 755 "$LOGS_DIR"
    
    log_info "✅ Directorios creados"
}

create_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        log_info "Creando archivo .env para v3.7..."
        
        cat > "$ENV_FILE" << 'EOF'
# ===============================================
# OCTOBER CMS v3.7 - Variables de Entorno
# ===============================================

# === OCTOBER CMS CONFIG ===
OCTOBER_ENV=development
OCTOBER_DEBUG=true
OCTOBER_URL=http://v3.october.local
OCTOBER_VERSION=3.7
LARAVEL_VERSION=10

# === DATABASE (Compartida) ===
DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=october_shared
DB_USERNAME=october_user
DB_PASSWORD=october_shared_2024
DB_PREFIX=v3_
DB_SCHEMA=october_v3

# === REDIS (Compartido) ===
REDIS_HOST=redis-shared
REDIS_PORT=6379
REDIS_DATABASE=0
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_DRIVER=redis

# === MAIL (Compartido) ===
MAIL_DRIVER=smtp
MAIL_HOST=mailhog-shared
MAIL_PORT=1025
MAIL_FROM_ADDRESS=noreply-v3@localhost
MAIL_FROM_NAME="October CMS v3.7"

# === ADMIN USER ===
ADMIN_EMAIL=admin-v3@localhost
ADMIN_PASSWORD=admin123v3
ADMIN_FIRST_NAME=Admin
ADMIN_LAST_NAME=v3.7

# === BUILDER PLUGIN ===
OCTOBER_BUILDER_ENABLE=true
OCTOBER_BUILDER_VERSION=3.x

# === PHP CONFIG ===
PHP_VERSION=8.1
PHP_MEMORY_LIMIT=512M
PHP_UPLOAD_MAX_FILESIZE=100M
PHP_POST_MAX_SIZE=100M
PHP_MAX_EXECUTION_TIME=300

# === DEVELOPMENT ===
APP_DEBUG=true
LOG_LEVEL=debug
EOF
        
        log_info "✅ Archivo .env creado"
    else
        log_info "✅ Archivo .env ya existe"
    fi
}

wait_for_container() {
    local max_attempts=30
    local attempt=1
    
    log_info "Esperando que el container v3.7 esté listo..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
            # Verificar PHP-FPM
            if docker exec "$CONTAINER_NAME" php-fpm8.1 -t &>/dev/null; then
                log_info "✅ Container v3.7 está listo"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    log_error "Timeout esperando container v3.7"
    return 1
}

check_october_installation() {
    if [[ ! -f "$OCTOBER_DIR/artisan" ]]; then
        return 1
    fi
    
    # Verificar si tiene tablas en la base de datos
    if docker exec "$CONTAINER_NAME" php artisan october:version &>/dev/null; then
        return 0
    fi
    
    return 1
}

# ============================================
# COMANDOS PRINCIPALES
# ============================================

cmd_start() {
    print_banner
    log_info "🚀 Iniciando October CMS v3.7..."
    
    check_dependencies
    create_directories
    create_env_file
    
    # Verificar si ya está corriendo
    if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_warn "Container v3.7 ya está corriendo"
        cmd_status
        return 0
    fi
    
    log_info "📦 Iniciando container..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    wait_for_container
    
    # Verificar instalación de October
    if ! check_october_installation; then
        log_warn "October CMS no está instalado o configurado"
        log_info "Ejecuta: $0 install"
    fi
    
    echo
    log_info "🎉 October CMS v3.7 iniciado exitosamente!"
    cmd_status
}

cmd_stop() {
    print_banner
    log_info "🛑 Deteniendo October CMS v3.7..."
    
    docker-compose -f "$COMPOSE_FILE" down
    
    log_info "✅ October v3.7 detenido"
}

cmd_restart() {
    log_info "🔄 Reiniciando October CMS v3.7..."
    cmd_stop
    sleep 3
    cmd_start
}

cmd_install() {
    print_banner
    log_info "📥 Instalando October CMS v3.7..."
    
    # Verificar que el container esté corriendo
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    # Verificar si ya está instalado
    if check_october_installation; then
        log_warn "October CMS ya está instalado"
        log_info "Para reinstalar, ejecuta: $0 clean && $0 start && $0 install"
        return 0
    fi
    
    # Crear project si no existe
    if [[ ! -f "$OCTOBER_DIR/composer.json" ]]; then
        log_info "📦 Descargando October CMS v3.7 via Composer..."
        docker exec -w /var/www/html "$CONTAINER_NAME" \
            composer create-project october/october . "3.7.*" --prefer-dist --no-interaction
    fi
    
    # Configurar permisos
    log_info "🔐 Configurando permisos..."
    docker exec "$CONTAINER_NAME" chown -R october:october /var/www/html
    docker exec "$CONTAINER_NAME" chmod -R 755 /var/www/html
    docker exec "$CONTAINER_NAME" chmod -R 777 storage bootstrap/cache
    
    # Crear .env de October
    log_info "⚙️ Configurando environment..."
    docker exec "$CONTAINER_NAME" cp .env.example .env || true
    
    # Generar APP_KEY
    docker exec "$CONTAINER_NAME" php artisan key:generate
    
    # Configurar base de datos en .env
    log_info "🗄️ Configurando base de datos..."
    docker exec "$CONTAINER_NAME" bash -c "cat > .env << 'EOF'
APP_DEBUG=true
APP_URL=http://v3.october.local
APP_KEY=$(php artisan --no-ansi key:generate --show)

# Database
DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=october_shared
DB_USERNAME=october_user
DB_PASSWORD=october_shared_2024
DB_PREFIX=v3_

# Redis
REDIS_HOST=redis-shared
REDIS_PORT=6379
REDIS_DATABASE=0

# Cache
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_DRIVER=redis

# Mail
MAIL_DRIVER=smtp
MAIL_HOST=mailhog-shared
MAIL_PORT=1025
MAIL_FROM_ADDRESS=noreply-v3@localhost
MAIL_FROM_NAME=\"October CMS v3.7\"

# October CMS
CMS_BACKEND_URI=admin
CMS_DISABLE_CORE_UPDATES=true
EOF"
    
    # Ejecutar migraciones
    log_info "🔄 Ejecutando migraciones..."
    docker exec "$CONTAINER_NAME" php artisan october:migrate
    
    # Crear usuario admin
    log_info "👤 Creando usuario administrador..."
    docker exec "$CONTAINER_NAME" php artisan create:admin \
        --email="admin-v3@localhost" \
        --password="admin123v3" \
        --first-name="Admin" \
        --last-name="v3.7" || true
    
    # Instalar Builder Plugin si está habilitado
    log_info "🔧 Instalando Builder Plugin..."
    docker exec "$CONTAINER_NAME" php artisan plugin:install RainLab.Builder || true
    
    # Limpiar cache
    log_info "🧹 Limpiando cache..."
    docker exec "$CONTAINER_NAME" php artisan cache:clear
    docker exec "$CONTAINER_NAME" php artisan view:clear
    docker exec "$CONTAINER_NAME" php artisan optimize:clear
    
    log_info "✅ October CMS v3.7 instalado exitosamente!"
    echo
    log_info "🌐 Accesos:"
    log_info "   Frontend: http://v3.october.local"
    log_info "   Backend:  http://v3.october.local/admin"
    log_info "   Email:    admin-v3@localhost"
    log_info "   Password: admin123v3"
}

cmd_status() {
    print_banner
    log_info "📊 Estado de October CMS v3.7:"
    echo
    
    # Estado del container
    echo -e "${BLUE}=== CONTAINER ===${NC}"
    if docker ps | grep -q "$CONTAINER_NAME"; then
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Container no está corriendo"
    fi
    echo
    
    # Estado de October
    echo -e "${BLUE}=== OCTOBER CMS v3.7 ===${NC}"
    if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        if check_october_installation; then
            echo "✅ October CMS: Instalado y funcionando"
            
            # Obtener versión
            local version=$(docker exec "$CONTAINER_NAME" php artisan october:version 2>/dev/null | grep "October CMS" || echo "Versión no detectada")
            echo "📦 $version"
            
            # Verificar plugins
            echo "🔧 Plugins instalados:"
            docker exec "$CONTAINER_NAME" php artisan plugin:list 2>/dev/null | head -10 || echo "   No se pueden listar plugins"
            
        else
            echo "❌ October CMS: No instalado"
            echo "   Ejecuta: $0 install"
        fi
    else
        echo "❌ Container no está corriendo"
    fi
    echo
    
    # URLs y accesos
    echo -e "${BLUE}=== ACCESOS ===${NC}"
    echo "🌐 Frontend:      http://v3.october.local"
    echo "🔧 Backend:       http://v3.october.local/admin"
    echo "📧 Email Admin:   admin-v3@localhost"
    echo "🔑 Password:      admin123v3"
    echo
    
    # Health checks
    echo -e "${BLUE}=== HEALTH CHECKS ===${NC}"
    
    # PHP-FPM
    if docker exec "$CONTAINER_NAME" php-fpm8.1 -t &>/dev/null; then
        echo "✅ PHP-FPM 8.1: OK"
    else
        echo "❌ PHP-FPM 8.1: Error"
    fi
    
    # Conectividad DB
    if docker exec "$CONTAINER_NAME" php artisan tinker --execute="DB::connection()->getPdo(); echo 'DB OK';" &>/dev/null; then
        echo "✅ Base de datos: Conectada"
    else
        echo "❌ Base de datos: Error de conexión"
    fi
    
    # Conectividad Redis
    if docker exec "$CONTAINER_NAME" php artisan tinker --execute="Redis::ping(); echo 'Redis OK';" &>/dev/null; then
        echo "✅ Redis: Conectado"
    else
        echo "❌ Redis: Error de conexión"
    fi
}

cmd_logs() {
    local service="${1:-}"
    local follow="${2:-false}"
    
    if [[ "$follow" == "follow" || "$follow" == "-f" ]]; then
        log_info "📋 Siguiendo logs de October v3.7..."
        docker-compose -f "$COMPOSE_FILE" logs -f
    else
        log_info "📋 Logs de October v3.7 (últimas 100 líneas):"
        docker-compose -f "$COMPOSE_FILE" logs --tail=100
    fi
}

cmd_artisan() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    log_info "🎯 Ejecutando Artisan: $*"
    docker exec -it "$CONTAINER_NAME" php artisan "$@"
}

cmd_composer() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    log_info "📦 Ejecutando Composer: $*"
    docker exec -it "$CONTAINER_NAME" composer "$@"
}

cmd_shell() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    log_info "🐚 Accediendo al shell del container..."
    docker exec -it "$CONTAINER_NAME" /bin/bash
}

cmd_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    print_banner
    log_info "💾 Creando backup de October CMS v3.7..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo"
        exit 1
    fi
    
    # Crear directorio de backup
    local backup_path="$BACKUP_DIR/v3_$timestamp"
    mkdir -p "$backup_path"
    
    # Backup base de datos (solo esquema v3)
    log_info "🗄️ Backing up database..."
    docker exec postgres-shared pg_dump -U october_user -n october_v3 october_shared > "$backup_path/database.sql"
    
    # Backup archivos de aplicación
    log_info "📁 Backing up application files..."
    tar -czf "$backup_path/october_files.tar.gz" -C "$OCTOBER_DIR" . 2>/dev/null
    
    # Backup configuraciones
    log_info "⚙️ Backing up configurations..."
    cp "$ENV_FILE" "$backup_path/dot_env" 2>/dev/null || true
    cp "$COMPOSE_FILE" "$backup_path/docker-compose.yml"
    
    # Información del backup
    cat > "$backup_path/backup_info.txt" << EOF
Backup October CMS v3.7
======================
Fecha: $(date)
Timestamp: $timestamp
Versión October: $(docker exec "$CONTAINER_NAME" php artisan october:version 2>/dev/null | head -1 || echo "No detectada")

Archivos incluidos:
- database.sql: Schema october_v3 completo
- october_files.tar.gz: Todos los archivos de October
- dot_env: Variables de entorno
- docker-compose.yml: Configuración Docker

Para restaurar:
1. $0 restore $backup_path
EOF
    
    log_info "✅ Backup creado en: $backup_path"
    log_info "📁 Tamaño: $(du -sh "$backup_path" | cut -f1)"
}

cmd_restore() {
    local backup_path="$1"
    
    if [[ -z "$backup_path" || ! -d "$backup_path" ]]; then
        log_error "Debes especificar una ruta de backup válida"
        log_info "Backups disponibles:"
        ls -la "$BACKUP_DIR/" | grep "v3_" || echo "No hay backups disponibles"
        return 1
    fi
    
    print_banner
    log_warn "⚠️  RESTAURANDO BACKUP DESDE: $backup_path"
    log_warn "Esto sobrescribirá los datos actuales de v3.7"
    
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        return 1
    fi
    
    # Detener container si está corriendo
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log_info "Deteniendo container..."
        cmd_stop
    fi
    
    # Restaurar archivos
    if [[ -f "$backup_path/october_files.tar.gz" ]]; then
        log_info "📁 Restaurando archivos de aplicación..."
        rm -rf "$OCTOBER_DIR"/*
        tar -xzf "$backup_path/october_files.tar.gz" -C "$OCTOBER_DIR/"
    fi
    
    # Restaurar .env
    if [[ -f "$backup_path/dot_env" ]]; then
        log_info "⚙️ Restaurando configuración..."
        cp "$backup_path/dot_env" "$ENV_FILE"
    fi
    
    # Iniciar container
    log_info "🚀 Iniciando container..."
    cmd_start
    
    # Restaurar base de datos
    if [[ -f "$backup_path/database.sql" ]]; then
        log_info "🗄️ Restaurando base de datos..."
        docker exec -i postgres-shared psql -U october_user -d october_shared < "$backup_path/database.sql"
    fi
    
    log_info "✅ Restore completado"
}

cmd_clean() {
    print_banner
    log_warn "🧹 Esta operación eliminará:"
    log_warn "- Container de October v3.7"
    log_warn "- Todos los archivos de aplicación"
    log_warn "- Datos en base de datos (esquema v3)"
    log_warn "- Logs y cache"
    echo
    
    read -p "¿Estás seguro? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        return 1
    fi
    
    log_info "Deteniendo container..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    
    log_info "Eliminando archivos de aplicación..."
    rm -rf "$OCTOBER_DIR"/*
    
    log_info "Limpiando logs..."
    rm -rf "$LOGS_DIR"/*
    
    log_info "Limpiando esquema de base de datos..."
    docker exec postgres-shared psql -U october_user -d october_shared -c "DROP SCHEMA IF EXISTS october_v3 CASCADE; CREATE SCHEMA october_v3;" || true
    
    log_info "✅ Limpieza completada"
}

cmd_update() {
    print_banner
    log_info "🔄 Actualizando October CMS v3.7..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    # Backup automático antes de actualizar
    log_info "💾 Creando backup automático..."
    cmd_backup
    
    # Actualizar Composer dependencies
    log_info "📦 Actualizando dependencias..."
    docker exec "$CONTAINER_NAME" composer update --no-interaction
    
    # Ejecutar migraciones
    log_info "🔄 Ejecutando migraciones..."
    docker exec "$CONTAINER_NAME" php artisan october:migrate
    
    # Limpiar cache
    log_info "🧹 Limpiando cache..."
    docker exec "$CONTAINER_NAME" php artisan cache:clear
    docker exec "$CONTAINER_NAME" php artisan optimize:clear
    
    log_info "✅ Actualización completada"
}

show_help() {
    print_banner
    echo -e "${BLUE}USO:${NC}"
    echo "  $0 <comando> [opciones]"
    echo
    echo -e "${BLUE}COMANDOS PRINCIPALES:${NC}"
    echo "  start              Iniciar October CMS v3.7"
    echo "  stop               Detener October CMS v3.7"
    echo "  restart            Reiniciar October CMS v3.7"
    echo "  status             Mostrar estado completo"
    echo "  install            Instalar October CMS v3.7"
    echo
    echo -e "${BLUE}DESARROLLO:${NC}"
    echo "  artisan <cmd>      Ejecutar comando Artisan"
    echo "  composer <cmd>     Ejecutar comando Composer"
    echo "  shell              Acceder al shell del container"
    echo "  logs [-f]          Ver logs (con -f para seguir)"
    echo
    echo -e "${BLUE}BACKUP Y RESTORE:${NC}"
    echo "  backup             Crear backup completo"
    echo "  restore <path>     Restaurar desde backup"
    echo
    echo -e "${BLUE}MANTENIMIENTO:${NC}"
    echo "  clean              Limpiar todo (files, DB, logs)"
    echo "  update             Actualizar October y dependencias"
    echo
    echo -e "${BLUE}EJEMPLOS:${NC}"
    echo "  $0 start                    # Iniciar v3.7"
    echo "  $0 install                  # Instalar October"
    echo "  $0 artisan october:version  # Ver versión"
    echo "  $0 composer require vendor/package"
    echo "  $0 backup                   # Crear backup"
    echo "  $0 logs -f                  # Seguir logs"
    echo
    echo -e "${BLUE}INFORMACIÓN:${NC}"
    echo "  Versión October: $OCTOBER_VERSION"
    echo "  Laravel: $LARAVEL_VERSION"
    echo "  PHP: $PHP_VERSION"
    echo "  Container: $CONTAINER_NAME"
    echo "  URL: http://$DOMAIN"
    echo
    echo -e "${YELLOW}NOTA:${NC} Requiere infraestructura compartida activa"
    echo "      Ejecuta: $SHARED_DIR/manage-shared.sh start"
}

# ============================================
# MAIN - PROCESAMIENTO DE ARGUMENTOS
# ============================================

main() {
    # Si no hay argumentos, mostrar ayuda
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "start")
            cmd_start "$@"
            ;;
        "stop")
            cmd_stop "$@"
            ;;
        "restart")
            cmd_restart "$@"
            ;;
        "install")
            cmd_install "$@"
            ;;
        "status")
            cmd_status "$@"
            ;;
        "logs")
            cmd_logs "$@"
            ;;
        "artisan")
            cmd_artisan "$@"
            ;;
        "composer")
            cmd_composer "$@"
            ;;
        "shell")
            cmd_shell "$@"
            ;;
        "backup")
            cmd_backup "$@"
            ;;
        "restore")
            cmd_restore "$@"
            ;;
        "clean")
            cmd_clean "$@"
            ;;
        "update")
            cmd_update "$@"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Comando desconocido: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal con todos los argumentos
main "$@"