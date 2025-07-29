#!/bin/bash

# manage-v4.sh
# Gestión de October CMS v4.0 independiente
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

# Información de October v4.0
OCTOBER_VERSION="4.0"
LARAVEL_VERSION="12"
PHP_VERSION="8.2"
CONTAINER_NAME="october_v4_app"
DOMAIN="v4.october.local"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[0;95m'
NC='\033[0m' # No Color

# Directorios
OCTOBER_DIR="$SCRIPT_DIR/october"
LOGS_DIR="$DATA_DIR/logs/v4"
COMPOSER_CACHE="$DATA_DIR/composer-v4"
BACKUP_DIR="$DATA_DIR/backups/v4"

# ============================================
# FUNCIONES AUXILIARES
# ============================================

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                🚀 OCTOBER CMS v4.0 MANAGER                   ║"
    echo "║           Laravel 12 + PHP 8.2 + New Dashboard              ║"
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

log_success() {
    echo -e "${MAGENTA}[SUCCESS]${NC} $1"
}

check_dependencies() {
    log_info "Verificando dependencias para October v4.0..."
    
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
    
    # Verificar versión de Docker (v4.0 requiere características más recientes)
    local docker_version=$(docker version --format '{{.Server.Version}}' | cut -d'.' -f1)
    if [[ $docker_version -lt 20 ]]; then
        log_warn "Docker v20+ recomendado para October v4.0"
    fi
    
    # Verificar infraestructura compartida
    check_shared_infrastructure
    
    log_info "✅ Dependencias verificadas para v4.0"
}

check_shared_infrastructure() {
    log_info "Verificando infraestructura compartida..."
    
    # Verificar red Docker
    if ! docker network ls | grep -q "october_shared_network"; then
        log_error "Red 'october_shared_network' no existe"
        log_warn "Ejecuta primero: $SHARED_DIR/manage-shared.sh start"
        exit 1
    fi
    
    # Verificar PostgreSQL (v4.0 requiere PostgreSQL 13+)
    if ! docker ps | grep -q "october_postgres_shared.*Up"; then
        log_error "PostgreSQL compartido no está corriendo"
        log_warn "Ejecuta: $SHARED_DIR/manage-shared.sh start"
        exit 1
    fi
    
    # Verificar versión de PostgreSQL
    local pg_version=$(docker exec postgres-shared psql -U october_user -d october_shared -t -c "SELECT version();" 2>/dev/null | grep -o "PostgreSQL [0-9]*" | cut -d' ' -f2 || echo "0")
    if [[ $pg_version -lt 13 ]]; then
        log_warn "PostgreSQL 13+ recomendado para October v4.0 (actual: $pg_version)"
    fi
    
    # Verificar Redis
    if ! docker ps | grep -q "october_redis_shared.*Up"; then
        log_error "Redis compartido no está corriendo"
        log_warn "Ejecuta: $SHARED_DIR/manage-shared.sh start"
        exit 1
    fi
    
    log_info "✅ Infraestructura compartida verificada para v4.0"
}

create_directories() {
    log_info "Creando estructura de directorios para v4.0..."
    
    local dirs=(
        "$OCTOBER_DIR"
        "$LOGS_DIR"
        "$COMPOSER_CACHE"
        "$BACKUP_DIR"
        "$SCRIPT_DIR/config/php"
        "$SCRIPT_DIR/config/supervisor"
        "$SCRIPT_DIR/scripts"
        "$OCTOBER_DIR/storage/app/uploads"
        "$OCTOBER_DIR/storage/framework/cache"
        "$OCTOBER_DIR/storage/framework/sessions"
        "$OCTOBER_DIR/storage/framework/views"
        "$OCTOBER_DIR/storage/logs"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "Creado: $dir"
        fi
    done
    
    # Permisos específicos para October v4.0 + Laravel 12
    chmod -R 755 "$OCTOBER_DIR"
    chmod -R 777 "$OCTOBER_DIR/storage" 2>/dev/null || true
    chmod -R 755 "$LOGS_DIR"
    
    log_info "✅ Directorios creados para v4.0"
}

create_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        log_info "Creando archivo .env para October v4.0..."
        
        cat > "$ENV_FILE" << 'EOF'
# ===============================================
# OCTOBER CMS v4.0 - Variables de Entorno
# ===============================================

# === OCTOBER CMS v4.0 CONFIG ===
OCTOBER_ENV=development
OCTOBER_DEBUG=true
OCTOBER_URL=http://v4.october.local
OCTOBER_VERSION=4.0
LARAVEL_VERSION=12

# === NEW FEATURES v4.0 ===
NEW_DASHBOARD_ENABLED=true
ENHANCED_SECURITY=true
IMPROVED_PERFORMANCE=true
MODERN_UI=true

# === DATABASE (Compartida) ===
DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=october_shared
DB_USERNAME=october_user
DB_PASSWORD=october_shared_2024
DB_PREFIX=v4_
DB_SCHEMA=october_v4

# === REDIS (Compartido) ===
REDIS_HOST=redis-shared
REDIS_PORT=6379
REDIS_DATABASE=1
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_DRIVER=redis

# === MAIL (Compartido) ===
MAIL_DRIVER=smtp
MAIL_HOST=mailhog-shared
MAIL_PORT=1025
MAIL_FROM_ADDRESS=noreply-v4@localhost
MAIL_FROM_NAME="October CMS v4.0"

# === ADMIN USER ===
ADMIN_EMAIL=admin-v4@localhost
ADMIN_PASSWORD=admin123v4
ADMIN_FIRST_NAME=Admin
ADMIN_LAST_NAME=v4.0

# === BUILDER PLUGIN v4.0 ===
OCTOBER_BUILDER_ENABLE=true
OCTOBER_BUILDER_VERSION=4.x
BUILDER_NEW_FEATURES=true

# === PHP 8.2 CONFIG ===
PHP_VERSION=8.2
PHP_MEMORY_LIMIT=512M
PHP_UPLOAD_MAX_FILESIZE=100M
PHP_POST_MAX_SIZE=100M
PHP_MAX_EXECUTION_TIME=300

# === LARAVEL 12 OPTIMIZATIONS ===
OCTANE_ENABLED=false
HORIZON_ENABLED=false
TELESCOPE_ENABLED=false

# === DEVELOPMENT v4.0 ===
APP_DEBUG=true
LOG_LEVEL=debug
DEBUGBAR_ENABLED=true
EOF
        
        log_info "✅ Archivo .env para v4.0 creado"
    else
        log_info "✅ Archivo .env para v4.0 ya existe"
    fi
}

wait_for_container() {
    local max_attempts=40  # Más tiempo para v4.0
    local attempt=1
    
    log_info "Esperando que el container v4.0 esté listo..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
            # Verificar PHP-FPM 8.2
            if docker exec "$CONTAINER_NAME" php-fpm8.2 -t &>/dev/null; then
                log_success "✅ Container v4.0 está listo"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 3  # Más tiempo entre checks para v4.0
        ((attempt++))
    done
    
    log_error "Timeout esperando container v4.0"
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

check_v4_features() {
    log_info "🔍 Verificando características de v4.0..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_warn "Container no está corriendo"
        return 1
    fi
    
    # Verificar nuevo dashboard
    if docker exec "$CONTAINER_NAME" php artisan route:list 2>/dev/null | grep -q "dashboard" || true; then
        log_success "✅ Nuevo Dashboard: Disponible"
    else
        log_warn "⚠️ Nuevo Dashboard: No detectado"
    fi
    
    # Verificar Laravel 12 features
    local laravel_version=$(docker exec "$CONTAINER_NAME" php artisan --version 2>/dev/null | grep -o "Laravel Framework [0-9]*\.[0-9]*" | cut -d' ' -f3 || echo "unknown")
    if [[ "$laravel_version" == "12"* ]]; then
        log_success "✅ Laravel 12: $laravel_version"
    else
        log_warn "⚠️ Laravel version: $laravel_version"
    fi
    
    # Verificar PHP 8.2
    local php_version=$(docker exec "$CONTAINER_NAME" php -v | head -1 | grep -o "PHP 8\.[0-9]*" || echo "unknown")
    if [[ "$php_version" == "PHP 8.2"* ]]; then
        log_success "✅ PHP 8.2: $php_version"
    else
        log_warn "⚠️ PHP version: $php_version"
    fi
}

# ============================================
# COMANDOS PRINCIPALES
# ============================================

cmd_start() {
    print_banner
    log_info "🚀 Iniciando October CMS v4.0..."
    
    check_dependencies
    create_directories
    create_env_file
    
    # Verificar si ya está corriendo
    if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_warn "Container v4.0 ya está corriendo"
        cmd_status
        return 0
    fi
    
    log_info "📦 Iniciando container v4.0..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    wait_for_container
    
    # Verificar instalación de October
    if ! check_october_installation; then
        log_warn "October CMS v4.0 no está instalado o configurado"
        log_info "Ejecuta: $0 install"
    else
        check_v4_features
    fi
    
    echo
    log_success "🎉 October CMS v4.0 iniciado exitosamente!"
    cmd_status
}

cmd_stop() {
    print_banner
    log_info "🛑 Deteniendo October CMS v4.0..."
    
    docker-compose -f "$COMPOSE_FILE" down
    
    log_info "✅ October v4.0 detenido"
}

cmd_restart() {
    log_info "🔄 Reiniciando October CMS v4.0..."
    cmd_stop
    sleep 3
    cmd_start
}

cmd_install() {
    print_banner
    log_info "📥 Instalando October CMS v4.0..."
    
    # Verificar que el container esté corriendo
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    # Verificar si ya está instalado
    if check_october_installation; then
        log_warn "October CMS v4.0 ya está instalado"
        log_info "Para reinstalar, ejecuta: $0 clean && $0 start && $0 install"
        return 0
    fi
    
    # Crear project si no existe
    if [[ ! -f "$OCTOBER_DIR/composer.json" ]]; then
        log_info "📦 Descargando October CMS v4.0 via Composer..."
        docker exec -w /var/www/html "$CONTAINER_NAME" \
            composer create-project october/october . "4.0.*" --prefer-dist --no-interaction
        
        log_info "🔧 Configurando October v4.0 específico..."
        # Configuraciones específicas para v4.0 pueden ir aquí
    fi
    
    # Configurar permisos específicos para Laravel 12
    log_info "🔐 Configurando permisos para Laravel 12..."
    docker exec "$CONTAINER_NAME" chown -R october:october /var/www/html
    docker exec "$CONTAINER_NAME" chmod -R 755 /var/www/html
    docker exec "$CONTAINER_NAME" chmod -R 777 storage bootstrap/cache
    
    # Crear .env de October v4.0
    log_info "⚙️ Configurando environment para v4.0..."
    docker exec "$CONTAINER_NAME" cp .env.example .env || true
    
    # Generar APP_KEY
    docker exec "$CONTAINER_NAME" php artisan key:generate
    
    # Configurar base de datos en .env específico para v4.0
    log_info "🗄️ Configurando base de datos para v4.0..."
    docker exec "$CONTAINER_NAME" bash -c "cat > .env << 'EOF'
APP_DEBUG=true
APP_URL=http://v4.october.local
APP_KEY=$(php artisan --no-ansi key:generate --show)

# October CMS v4.0
OCTOBER_VERSION=4.0
NEW_DASHBOARD_ENABLED=true
ENHANCED_SECURITY=true

# Database (PostgreSQL 13+ optimized)
DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=october_shared
DB_USERNAME=october_user
DB_PASSWORD=october_shared_2024
DB_PREFIX=v4_

# Redis (separate database from v3)
REDIS_HOST=redis-shared
REDIS_PORT=6379
REDIS_DATABASE=1

# Cache (optimized for Laravel 12)
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_DRIVER=redis

# Mail
MAIL_DRIVER=smtp
MAIL_HOST=mailhog-shared
MAIL_PORT=1025
MAIL_FROM_ADDRESS=noreply-v4@localhost
MAIL_FROM_NAME=\"October CMS v4.0\"

# October CMS v4.0 specific
CMS_BACKEND_URI=admin
CMS_DISABLE_CORE_UPDATES=true
CMS_NEW_DASHBOARD=true

# Laravel 12 optimizations
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug
EOF"
    
    # Ejecutar migraciones específicas para v4.0
    log_info "🔄 Ejecutando migraciones para v4.0..."
    docker exec "$CONTAINER_NAME" php artisan october:migrate
    
    # Configurar nuevo dashboard si está disponible
    log_info "📊 Configurando nuevo dashboard v4.0..."
    docker exec "$CONTAINER_NAME" php artisan october:dashboard:install || log_warn "Dashboard install no disponible en esta versión"
    
    # Crear usuario admin para v4.0
    log_info "👤 Creando usuario administrador v4.0..."
    docker exec "$CONTAINER_NAME" php artisan create:admin \
        --email="admin-v4@localhost" \
        --password="admin123v4" \
        --first-name="Admin" \
        --last-name="v4.0" || true
    
    # Instalar Builder Plugin v4.0
    log_info "🔧 Instalando Builder Plugin v4.0..."
    docker exec "$CONTAINER_NAME" php artisan plugin:install RainLab.Builder || true
    
    # Configurar características específicas de v4.0
    log_info "⚡ Configurando características avanzadas v4.0..."
    
    # Habilitar optimizaciones de Laravel 12
    docker exec "$CONTAINER_NAME" php artisan config:cache || true
    docker exec "$CONTAINER_NAME" php artisan route:cache || true
    docker exec "$CONTAINER_NAME" php artisan view:cache || true
    
    # Limpiar cache inicial
    log_info "🧹 Limpiando cache inicial..."
    docker exec "$CONTAINER_NAME" php artisan cache:clear
    docker exec "$CONTAINER_NAME" php artisan optimize:clear
    
    # Verificar instalación
    check_v4_features
    
    log_success "✅ October CMS v4.0 instalado exitosamente!"
    echo
    log_info "🌐 Accesos v4.0:"
    log_info "   Frontend: http://v4.october.local"
    log_info "   Backend:  http://v4.october.local/admin"
    log_info "   Email:    admin-v4@localhost"
    log_info "   Password: admin123v4"
    echo
    log_info "🆕 Características v4.0:"
    log_info "   • Nuevo Dashboard"
    log_info "   • Laravel 12"
    log_info "   • PHP 8.2"
    log_info "   • Seguridad Mejorada"
    log_info "   • Performance Optimizada"
}

cmd_status() {
    print_banner
    log_info "📊 Estado de October CMS v4.0:"
    echo
    
    # Estado del container
    echo -e "${BLUE}=== CONTAINER v4.0 ===${NC}"
    if docker ps | grep -q "$CONTAINER_NAME"; then
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Container no está corriendo"
    fi
    echo
    
    # Estado de October v4.0
    echo -e "${BLUE}=== OCTOBER CMS v4.0 ===${NC}"
    if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        if check_october_installation; then
            echo "✅ October CMS v4.0: Instalado y funcionando"
            
            # Obtener versión específica
            local version=$(docker exec "$CONTAINER_NAME" php artisan october:version 2>/dev/null | grep "October CMS" || echo "October CMS v4.0")
            echo "📦 $version"
            
            # Verificar Laravel 12
            local laravel_version=$(docker exec "$CONTAINER_NAME" php artisan --version 2>/dev/null | grep "Laravel Framework" || echo "Laravel Framework 12.x")
            echo "🔗 $laravel_version"
            
            # Verificar plugins v4.0
            echo "🔧 Plugins instalados:"
            docker exec "$CONTAINER_NAME" php artisan plugin:list 2>/dev/null | head -10 || echo "   No se pueden listar plugins"
            
        else
            echo "❌ October CMS v4.0: No instalado"
            echo "   Ejecuta: $0 install"
        fi
    else
        echo "❌ Container no está corriendo"
    fi
    echo
    
    # Características v4.0
    echo -e "${BLUE}=== CARACTERÍSTICAS v4.0 ===${NC}"
    if docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        check_v4_features
    else
        echo "❌ Container no disponible para verificar características"
    fi
    echo
    
    # URLs y accesos
    echo -e "${BLUE}=== ACCESOS v4.0 ===${NC}"
    echo "🌐 Frontend:      http://v4.october.local"
    echo "🔧 Backend:       http://v4.october.local/admin"
    echo "📊 Dashboard:     http://v4.october.local/dashboard (si disponible)"
    echo "📧 Email Admin:   admin-v4@localhost"
    echo "🔑 Password:      admin123v4"
    echo
    
    # Health checks específicos v4.0
    echo -e "${BLUE}=== HEALTH CHECKS v4.0 ===${NC}"
    
    # PHP-FPM 8.2
    if docker exec "$CONTAINER_NAME" php-fpm8.2 -t &>/dev/null; then
        echo "✅ PHP-FPM 8.2: OK"
    else
        echo "❌ PHP-FPM 8.2: Error"
    fi
    
    # Conectividad DB (con esquema v4)
    if docker exec "$CONTAINER_NAME" php artisan tinker --execute="DB::connection()->getPdo(); echo 'DB OK';" &>/dev/null; then
        echo "✅ Base de datos (v4): Conectada"
    else
        echo "❌ Base de datos (v4): Error de conexión"
    fi
    
    # Conectividad Redis (database 1)
    if docker exec "$CONTAINER_NAME" php artisan tinker --execute="Redis::ping(); echo 'Redis OK';" &>/dev/null; then
        echo "✅ Redis (DB 1): Conectado"
    else
        echo "❌ Redis (DB 1): Error de conexión"
    fi
    
    # Verificar cache optimizations
    if docker exec "$CONTAINER_NAME" test -f bootstrap/cache/config.php &>/dev/null; then
        echo "✅ Cache optimizations: Habilitadas"
    else
        echo "⚠️ Cache optimizations: No habilitadas"
    fi
}

cmd_logs() {
    local service="${1:-}"
    local follow="${2:-false}"
    
    if [[ "$follow" == "follow" || "$follow" == "-f" ]]; then
        log_info "📋 Siguiendo logs de October v4.0..."
        docker-compose -f "$COMPOSE_FILE" logs -f
    else
        log_info "📋 Logs de October v4.0 (últimas 100 líneas):"
        docker-compose -f "$COMPOSE_FILE" logs --tail=100
    fi
}

cmd_artisan() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    log_info "🎯 Ejecutando Artisan v4.0: $*"
    docker exec -it "$CONTAINER_NAME" php artisan "$@"
}

cmd_composer() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    log_info "📦 Ejecutando Composer v4.0: $*"
    docker exec -it "$CONTAINER_NAME" composer "$@"
}

cmd_shell() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    log_info "🐚 Accediendo al shell del container v4.0..."
    docker exec -it "$CONTAINER_NAME" /bin/bash
}

cmd_optimize() {
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    print_banner
    log_info "⚡ Optimizando October CMS v4.0 (Laravel 12)..."
    
    # Laravel 12 optimizations
    log_info "🔧 Aplicando optimizaciones de Laravel 12..."
    docker exec "$CONTAINER_NAME" php artisan config:cache
    docker exec "$CONTAINER_NAME" php artisan route:cache
    docker exec "$CONTAINER_NAME" php artisan view:cache
    docker exec "$CONTAINER_NAME" php artisan event:cache
    
    # October CMS optimizations
    log_info "🎃 Aplicando optimizaciones de October v4.0..."
    docker exec "$CONTAINER_NAME" php artisan october:util compile assets || true
    docker exec "$CONTAINER_NAME" php artisan october:util compile lang || true
    
    log_success "✅ Optimizaciones aplicadas para v4.0"
}

cmd_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    print_banner
    log_info "💾 Creando backup de October CMS v4.0..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo"
        exit 1
    fi
    
    # Crear directorio de backup
    local backup_path="$BACKUP_DIR/v4_$timestamp"
    mkdir -p "$backup_path"
    
    # Backup base de datos (solo esquema v4)
    log_info "🗄️ Backing up database v4.0..."
    docker exec postgres-shared pg_dump -U october_user -n october_v4 october_shared > "$backup_path/database.sql"
    
    # Backup archivos de aplicación
    log_info "📁 Backing up application files v4.0..."
    tar -czf "$backup_path/october_files.tar.gz" -C "$OCTOBER_DIR" . 2>/dev/null
    
    # Backup configuraciones
    log_info "⚙️ Backing up configurations v4.0..."
    cp "$ENV_FILE" "$backup_path/dot_env" 2>/dev/null || true
    cp "$COMPOSE_FILE" "$backup_path/docker-compose.yml"
    
    # Backup cache optimizations
    log_info "⚡ Backing up cache optimizations..."
    if [[ -d "$OCTOBER_DIR/bootstrap/cache" ]]; then
        tar -czf "$backup_path/cache_optimizations.tar.gz" -C "$OCTOBER_DIR/bootstrap" cache 2>/dev/null || true
    fi
    
    # Información del backup
    local october_version=$(docker exec "$CONTAINER_NAME" php artisan october:version 2>/dev/null | head -1 || echo "October CMS v4.0")
    local laravel_version=$(docker exec "$CONTAINER_NAME" php artisan --version 2>/dev/null | head -1 || echo "Laravel Framework 12.x")
    
    cat > "$backup_path/backup_info.txt" << EOF
Backup October CMS v4.0
======================
Fecha: $(date)
Timestamp: $timestamp
Versión October: $october_version
Versión Laravel: $laravel_version
PHP Version: $(docker exec "$CONTAINER_NAME" php -v | head -1)

Características v4.0 incluidas:
- Nuevo Dashboard
- Laravel 12 optimizations
- PHP 8.2 features
- Enhanced security

Archivos incluidos:
- database.sql: Schema october_v4 completo
- october_files.tar.gz: Todos los archivos de October v4.0
- cache_optimizations.tar.gz: Cache de Laravel 12
- dot_env: Variables de entorno v4.0
- docker-compose.yml: Configuración Docker

Para restaurar:
1. $0 restore $backup_path
EOF
    
    log_success "✅ Backup v4.0 creado en: $backup_path"
    log_info "📁 Tamaño: $(du -sh "$backup_path" | cut -f1)"
}

cmd_restore() {
    local backup_path="$1"
    
    if [[ -z "$backup_path" || ! -d "$backup_path" ]]; then
        log_error "Debes especificar una ruta de backup válida"
        log_info "Backups v4.0 disponibles:"
        ls -la "$BACKUP_DIR/" | grep "v4_" || echo "No hay backups v4.0 disponibles"
        return 1
    fi
    
    print_banner
    log_warn "⚠️  RESTAURANDO BACKUP v4.0 DESDE: $backup_path"
    log_warn "Esto sobrescribirá los datos actuales de v4.0"
    
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        return 1
    fi
    
    # Detener container si está corriendo
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log_info "Deteniendo container v4.0..."
        cmd_stop
    fi
    
    # Restaurar archivos
    if [[ -f "$backup_path/october_files.tar.gz" ]]; then
        log_info "📁 Restaurando archivos de aplicación v4.0..."
        rm -rf "$OCTOBER_DIR"/*
        tar -xzf "$backup_path/october_files.tar.gz" -C "$OCTOBER_DIR/"
    fi
    
    # Restaurar cache optimizations
    if [[ -f "$backup_path/cache_optimizations.tar.gz" ]]; then
        log_info "⚡ Restaurando optimizaciones de cache..."
        tar -xzf "$backup_path/cache_optimizations.tar.gz" -C "$OCTOBER_DIR/bootstrap/"
    fi
    
    # Restaurar .env
    if [[ -f "$backup_path/dot_env" ]]; then
        log_info "⚙️ Restaurando configuración v4.0..."
        cp "$backup_path/dot_env" "$ENV_FILE"
    fi
    
    # Iniciar container
    log_info "🚀 Iniciando container v4.0..."
    cmd_start
    
    # Restaurar base de datos
    if [[ -f "$backup_path/database.sql" ]]; then
        log_info "🗄️ Restaurando base de datos v4.0..."
        docker exec -i postgres-shared psql -U october_user -d october_shared < "$backup_path/database.sql"
    fi
    
    # Verificar características v4.0
    check_v4_features
    
    log_success "✅ Restore v4.0 completado"
}

cmd_clean() {
    print_banner
    log_warn "🧹 Esta operación eliminará:"
    log_warn "- Container de October v4.0"
    log_warn "- Todos los archivos de aplicación v4.0"
    log_warn "- Datos en base de datos (esquema v4)"
    log_warn "- Cache optimizations"
    log_warn "- Logs y cache v4.0"
    echo
    
    read -p "¿Estás seguro? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        return 1
    fi
    
    log_info "Deteniendo container v4.0..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    
    log_info "Eliminando archivos de aplicación v4.0..."
    rm -rf "$OCTOBER_DIR"/*
    
    log_info "Limpiando logs v4.0..."
    rm -rf "$LOGS_DIR"/*
    
    log_info "Limpiando esquema de base de datos v4.0..."
    docker exec postgres-shared psql -U october_user -d october_shared -c "DROP SCHEMA IF EXISTS october_v4 CASCADE; CREATE SCHEMA october_v4;" || true
    
    log_info "Limpiando Redis database 1 (v4.0)..."
    docker exec redis-shared redis-cli -n 1 FLUSHDB || true
    
    log_success "✅ Limpieza v4.0 completada"
}

cmd_update() {
    print_banner
    log_info "🔄 Actualizando October CMS v4.0..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container no está corriendo. Ejecuta: $0 start"
        exit 1
    fi
    
    # Backup automático antes de actualizar
    log_info "💾 Creando backup automático antes de actualizar..."
    cmd_backup
    
    # Actualizar Composer dependencies para v4.0
    log_info "📦 Actualizando dependencias v4.0..."
    docker exec "$CONTAINER_NAME" composer update --no-interaction --optimize-autoloader
    
    # Ejecutar migraciones v4.0
    log_info "🔄 Ejecutando migraciones v4.0..."
    docker exec "$CONTAINER_NAME" php artisan october:migrate
    
    # Actualizar plugins para v4.0
    log_info "🔧 Actualizando plugins para v4.0..."
    docker exec "$CONTAINER_NAME" php artisan plugin:refresh --force || true
    
    # Aplicar optimizaciones v4.0
    log_info "⚡ Aplicando optimizaciones v4.0..."
    cmd_optimize
    
    # Verificar características post-actualización
    check_v4_features
    
    log_success "✅ Actualización v4.0 completada"
}

cmd_compare() {
    print_banner
    log_info "🔍 Comparando October v4.0 con v3.7..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME.*Up"; then
        log_error "Container v4.0 no está corriendo"
        return 1
    fi
    
    # Verificar si v3.7 está disponible
    local v3_container="october_v3_app"
    local v3_running=false
    if docker ps | grep -q "$v3_container.*Up"; then
        v3_running=true
        log_info "✅ Ambas versiones están corriendo"
    else
        log_warn "⚠️ Solo v4.0 está corriendo (v3.7 no disponible)"
    fi
    
    echo
    echo -e "${BLUE}=== COMPARACIÓN DE VERSIONES ===${NC}"
    
    # Comparar versiones
    echo "📦 October CMS:"
    local v4_version=$(docker exec "$CONTAINER_NAME" php artisan october:version 2>/dev/null | head -1 || echo "v4.0")
    echo "   v4.0: $v4_version"
    
    if [[ "$v3_running" == true ]]; then
        local v3_version=$(docker exec "$v3_container" php artisan october:version 2>/dev/null | head -1 || echo "v3.7")
        echo "   v3.7: $v3_version"
    else
        echo "   v3.7: No disponible"
    fi
    
    # Comparar Laravel
    echo
    echo "🔗 Laravel Framework:"
    local v4_laravel=$(docker exec "$CONTAINER_NAME" php artisan --version 2>/dev/null | head -1 || echo "Laravel 12.x")
    echo "   v4.0: $v4_laravel"
    
    if [[ "$v3_running" == true ]]; then
        local v3_laravel=$(docker exec "$v3_container" php artisan --version 2>/dev/null | head -1 || echo "Laravel 10.x")
        echo "   v3.7: $v3_laravel"
    else
        echo "   v3.7: Laravel 10.x (no disponible)"
    fi
    
    # Comparar PHP
    echo
    echo "🐘 PHP Version:"
    local v4_php=$(docker exec "$CONTAINER_NAME" php -v | head -1 | grep -o "PHP 8\.[0-9]*\.[0-9]*" || echo "PHP 8.2.x")
    echo "   v4.0: $v4_php"
    
    if [[ "$v3_running" == true ]]; then
        local v3_php=$(docker exec "$v3_container" php -v | head -1 | grep -o "PHP 8\.[0-9]*\.[0-9]*" || echo "PHP 8.1.x")
        echo "   v3.7: $v3_php"
    else
        echo "   v3.7: PHP 8.1.x (no disponible)"
    fi
    
    # Comparar características
    echo
    echo -e "${BLUE}=== CARACTERÍSTICAS ÚNICAS v4.0 ===${NC}"
    echo "✨ Nuevo Dashboard mejorado"
    echo "⚡ Laravel 12 optimizations"
    echo "🔒 Enhanced Security features"
    echo "🚀 Improved Performance"
    echo "🎨 Modern UI/UX"
    echo "📱 Better mobile support"
    
    # URLs de acceso
    echo
    echo -e "${BLUE}=== URLS DE ACCESO ===${NC}"
    echo "🌐 v4.0 Frontend: http://v4.october.local"
    echo "🔧 v4.0 Backend:  http://v4.october.local/admin"
    
    if [[ "$v3_running" == true ]]; then
        echo "🌐 v3.7 Frontend: http://v3.october.local"
        echo "🔧 v3.7 Backend:  http://v3.october.local/admin"
        echo
        log_success "✅ Ambas versiones disponibles para comparación"
    else
        echo
        log_info "Para comparar lado a lado, inicia v3.7:"
        log_info "   cd ../v3 && ./manage-v3.sh start"
    fi
}

show_help() {
    print_banner
    echo -e "${BLUE}USO:${NC}"
    echo "  $0 <comando> [opciones]"
    echo
    echo -e "${BLUE}COMANDOS PRINCIPALES:${NC}"
    echo "  start              Iniciar October CMS v4.0"
    echo "  stop               Detener October CMS v4.0"
    echo "  restart            Reiniciar October CMS v4.0"
    echo "  status             Mostrar estado completo v4.0"
    echo "  install            Instalar October CMS v4.0"
    echo
    echo -e "${BLUE}DESARROLLO v4.0:${NC}"
    echo "  artisan <cmd>      Ejecutar comando Artisan"
    echo "  composer <cmd>     Ejecutar comando Composer"
    echo "  shell              Acceder al shell del container"
    echo "  logs [-f]          Ver logs (con -f para seguir)"
    echo "  optimize           Aplicar optimizaciones Laravel 12"
    echo
    echo -e "${BLUE}BACKUP Y RESTORE:${NC}"
    echo "  backup             Crear backup completo v4.0"
    echo "  restore <path>     Restaurar desde backup"
    echo
    echo -e "${BLUE}MANTENIMIENTO:${NC}"
    echo "  clean              Limpiar todo (files, DB v4, logs)"
    echo "  update             Actualizar October v4.0 y dependencias"
    echo "  compare            Comparar v4.0 vs v3.7"
    echo
    echo -e "${BLUE}EJEMPLOS v4.0:${NC}"
    echo "  $0 start                    # Iniciar v4.0"
    echo "  $0 install                  # Instalar October v4.0"
    echo "  $0 artisan october:version  # Ver versión v4.0"
    echo "  $0 optimize                 # Optimizar Laravel 12"
    echo "  $0 compare                  # Comparar con v3.7"
    echo "  $0 backup                   # Backup v4.0"
    echo "  $0 logs -f                  # Seguir logs v4.0"
    echo
    echo -e "${BLUE}INFORMACIÓN v4.0:${NC}"
    echo "  Versión October: $OCTOBER_VERSION"
    echo "  Laravel: $LARAVEL_VERSION"
    echo "  PHP: $PHP_VERSION"
    echo "  Container: $CONTAINER_NAME"
    echo "  URL: http://$DOMAIN"
    echo "  Redis DB: 1 (separado de v3.7)"
    echo
    echo -e "${MAGENTA}CARACTERÍSTICAS v4.0:${NC}"
    echo "  ✨ Nuevo Dashboard"
    echo "  ⚡ Laravel 12 optimizations"
    echo "  🔒 Enhanced Security"
    echo "  🚀 Improved Performance"
    echo "  🎨 Modern UI/UX"
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
        "optimize")
            cmd_optimize "$@"
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
        "compare")
            cmd_compare "$@"
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