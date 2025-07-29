#!/bin/bash

# manage-shared.sh
# Gestión de infraestructura compartida para October CMS multi-versión
# Autor: framirez@healthytek.cl
# Versión: 1.0

set -euo pipefail

# ============================================
# CONFIGURACIÓN Y VARIABLES
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración por defecto
DEFAULT_PROFILE="development"
BACKUP_DIR="$DATA_DIR/backups"
LOG_DIR="$DATA_DIR/nginx-logs"

# ============================================
# FUNCIONES AUXILIARES
# ============================================

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║               🏗️  OCTOBER CMS - INFRAESTRUCTURA              ║"
    echo "║                    Gestión Compartida v1.0                   ║"
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
    log_info "Verificando dependencias del sistema..."
    
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
    
    # Verificar permisos Docker
    if ! docker info &> /dev/null; then
        log_error "No tienes permisos para ejecutar Docker"
        log_warn "Ejecuta: sudo usermod -aG docker \$USER && newgrp docker"
        exit 1
    fi
    
    log_info "✅ Dependencias verificadas correctamente"
}

create_data_directories() {
    log_info "Creando estructura de directorios de datos..."
    
    local dirs=(
        "$DATA_DIR"
        "$DATA_DIR/postgres"
        "$DATA_DIR/redis"
        "$DATA_DIR/nginx-logs"
        "$DATA_DIR/ssl"
        "$BACKUP_DIR"
        "$BACKUP_DIR/postgres"
        "$BACKUP_DIR/redis"
        "$BACKUP_DIR/nginx"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "Creado: $dir"
        fi
    done
    
    # Configurar permisos
    chmod -R 755 "$DATA_DIR"
    
    log_info "✅ Estructura de directorios creada"
}

check_network() {
    log_info "Verificando red Docker..."
    
    if ! docker network ls | grep -q "october_shared_network"; then
        log_info "Creando red Docker compartida..."
        docker network create \
            --driver bridge \
            --subnet=172.30.0.0/16 \
            --gateway=172.30.0.1 \
            october_shared_network
        log_info "✅ Red 'october_shared_network' creada"
    else
        log_info "✅ Red 'october_shared_network' ya existe"
    fi
}

wait_for_service() {
    local service_name="$1"
    local max_attempts="${2:-30}"
    local attempt=1
    
    log_info "Esperando que '$service_name' esté listo..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f "$COMPOSE_FILE" ps "$service_name" | grep -q "Up"; then
            # Verificar health check específico
            case "$service_name" in
                "postgres-shared")
                    if docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared pg_isready -U october_user -d october_shared &>/dev/null; then
                        log_info "✅ PostgreSQL está listo"
                        return 0
                    fi
                    ;;
                "redis-shared")
                    if docker-compose -f "$COMPOSE_FILE" exec -T redis-shared redis-cli ping &>/dev/null; then
                        log_info "✅ Redis está listo"
                        return 0
                    fi
                    ;;
                "nginx-shared")
                    if docker-compose -f "$COMPOSE_FILE" exec -T nginx-shared nginx -t &>/dev/null; then
                        log_info "✅ NGINX está listo"
                        return 0
                    fi
                    ;;
                *)
                    log_info "✅ $service_name está listo"
                    return 0
                    ;;
            esac
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    log_error "Timeout esperando '$service_name'"
    return 1
}

# ============================================
# COMANDOS PRINCIPALES
# ============================================

cmd_start() {
    local profile="${1:-$DEFAULT_PROFILE}"
    
    print_banner
    log_info "🚀 Iniciando infraestructura compartida..."
    log_info "Perfil: $profile"
    
    check_dependencies
    create_data_directories
    check_network
    
    # Iniciar servicios por etapas
    log_info "📦 Iniciando servicios de base de datos..."
    docker-compose -f "$COMPOSE_FILE" --profile "$profile" up -d postgres-shared redis-shared
    
    # Esperar que estén listos
    wait_for_service "postgres-shared"
    wait_for_service "redis-shared"
    
    log_info "🌐 Iniciando servicios web..."
    docker-compose -f "$COMPOSE_FILE" --profile "$profile" up -d nginx-shared
    
    wait_for_service "nginx-shared"
    
    # Servicios opcionales para desarrollo
    if [[ "$profile" == "development" ]]; then
        log_info "🛠️ Iniciando servicios de desarrollo..."
        docker-compose -f "$COMPOSE_FILE" --profile development up -d mailhog-shared adminer-shared
    fi
    
    echo
    log_info "🎉 Infraestructura compartida iniciada exitosamente!"
    cmd_status
}

cmd_stop() {
    print_banner
    log_info "🛑 Deteniendo infraestructura compartida..."
    
    docker-compose -f "$COMPOSE_FILE" down
    
    log_info "✅ Infraestructura detenida"
}

cmd_restart() {
    log_info "🔄 Reiniciando infraestructura compartida..."
    cmd_stop
    sleep 3
    cmd_start "$@"
}

cmd_status() {
    print_banner
    log_info "📊 Estado de la infraestructura compartida:"
    echo
    
    # Estado de containers
    echo -e "${BLUE}=== CONTAINERS ===${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
    echo
    
    # Estado de red
    echo -e "${BLUE}=== RED DOCKER ===${NC}"
    if docker network ls | grep -q "october_shared_network"; then
        docker network inspect october_shared_network --format "{{.Name}}: {{.IPAM.Config}}"
    else
        echo "❌ Red 'october_shared_network' no existe"
    fi
    echo
    
    # URLs de acceso
    echo -e "${BLUE}=== URLS DE ACCESO ===${NC}"
    echo "🗄️  Adminer (DB):     http://localhost:8080"
    echo "📧 MailHog:          http://localhost:8025"
    echo "🐘 PostgreSQL:       localhost:5432"
    echo "🔴 Redis:            localhost:6379"
    echo
    
    # Verificar conectividad
    echo -e "${BLUE}=== HEALTH CHECKS ===${NC}"
    
    # PostgreSQL
    if docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared pg_isready -U october_user -d october_shared &>/dev/null; then
        echo "✅ PostgreSQL: Conectado"
    else
        echo "❌ PostgreSQL: Desconectado"
    fi
    
    # Redis
    if docker-compose -f "$COMPOSE_FILE" exec -T redis-shared redis-cli ping &>/dev/null; then
        echo "✅ Redis: Conectado"
    else
        echo "❌ Redis: Desconectado"
    fi
    
    # NGINX
    if docker-compose -f "$COMPOSE_FILE" exec -T nginx-shared nginx -t &>/dev/null; then
        echo "✅ NGINX: Configuración válida"
    else
        echo "❌ NGINX: Error en configuración"
    fi
}

cmd_logs() {
    local service="${1:-}"
    local follow="${2:-false}"
    
    if [[ -z "$service" ]]; then
        log_info "📋 Logs de todos los servicios (últimas 50 líneas):"
        docker-compose -f "$COMPOSE_FILE" logs --tail=50
        return
    fi
    
    if [[ "$follow" == "follow" || "$follow" == "-f" ]]; then
        log_info "📋 Siguiendo logs de '$service'..."
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        log_info "📋 Logs de '$service' (últimas 100 líneas):"
        docker-compose -f "$COMPOSE_FILE" logs --tail=100 "$service"
    fi
}

cmd_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    print_banner
    log_info "💾 Creando backup de la infraestructura..."
    
    # Crear directorio de backup
    local backup_path="$BACKUP_DIR/shared_$timestamp"
    mkdir -p "$backup_path"
    
    # Backup PostgreSQL
    log_info "🐘 Backing up PostgreSQL..."
    docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared pg_dumpall -U october_user > "$backup_path/postgres_full.sql"
    
    # Backup específico por esquema
    docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared pg_dump -U october_user -n october_v3 october_shared > "$backup_path/postgres_v3.sql"
    docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared pg_dump -U october_user -n october_v4 october_shared > "$backup_path/postgres_v4.sql"
    
    # Backup Redis (si tiene datos)
    log_info "🔴 Backing up Redis..."
    docker-compose -f "$COMPOSE_FILE" exec -T redis-shared redis-cli BGSAVE
    sleep 2
    docker cp $(docker-compose -f "$COMPOSE_FILE" ps -q redis-shared):/data/dump.rdb "$backup_path/redis_dump.rdb" 2>/dev/null || true
    
    # Backup configuraciones
    log_info "⚙️ Backing up configuraciones..."
    cp -r "$SCRIPT_DIR/nginx" "$backup_path/"
    cp "$COMPOSE_FILE" "$backup_path/"
    
    # Crear archivo de información
    cat > "$backup_path/backup_info.txt" << EOF
Backup de Infraestructura Compartida October CMS
================================================
Fecha: $(date)
Timestamp: $timestamp
Servicios incluidos:
- PostgreSQL (full + esquemas v3/v4)
- Redis 
- Configuraciones NGINX
- Docker Compose

Archivos:
- postgres_full.sql: Dump completo de PostgreSQL
- postgres_v3.sql: Solo esquema october_v3
- postgres_v4.sql: Solo esquema october_v4
- redis_dump.rdb: Datos de Redis
- nginx/: Configuraciones NGINX
- docker-compose.yml: Configuración Docker
EOF
    
    log_info "✅ Backup creado en: $backup_path"
    log_info "📁 Tamaño: $(du -sh "$backup_path" | cut -f1)"
}

cmd_restore() {
    local backup_path="$1"
    
    if [[ -z "$backup_path" || ! -d "$backup_path" ]]; then
        log_error "Debes especificar una ruta de backup válida"
        log_info "Backups disponibles:"
        ls -la "$BACKUP_DIR/" | grep "shared_" || echo "No hay backups disponibles"
        return 1
    fi
    
    print_banner
    log_warn "⚠️  RESTAURANDO BACKUP DESDE: $backup_path"
    log_warn "Esto sobrescribirá los datos actuales"
    
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        return 1
    fi
    
    # Verificar que los servicios estén corriendo
    if ! docker-compose -f "$COMPOSE_FILE" ps postgres-shared | grep -q "Up"; then
        log_error "PostgreSQL no está corriendo. Inicia los servicios primero."
        return 1
    fi
    
    # Restaurar PostgreSQL
    if [[ -f "$backup_path/postgres_full.sql" ]]; then
        log_info "🐘 Restaurando PostgreSQL..."
        docker-compose -f "$COMPOSE_FILE" exec -T postgres-shared psql -U october_user -d postgres < "$backup_path/postgres_full.sql"
    fi
    
    # Restaurar Redis
    if [[ -f "$backup_path/redis_dump.rdb" ]]; then
        log_info "🔴 Restaurando Redis..."
        docker-compose -f "$COMPOSE_FILE" stop redis-shared
        docker cp "$backup_path/redis_dump.rdb" $(docker-compose -f "$COMPOSE_FILE" ps -q redis-shared):/data/dump.rdb
        docker-compose -f "$COMPOSE_FILE" start redis-shared
    fi
    
    log_info "✅ Restore completado"
}

cmd_clean() {
    print_banner
    log_warn "🧹 Esta operación eliminará:"
    log_warn "- Todos los containers"
    log_warn "- Volúmenes de datos"
    log_warn "- Red Docker"
    log_warn "- Logs"
    echo
    
    read -p "¿Estás seguro? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operación cancelada"
        return 1
    fi
    
    log_info "Deteniendo servicios..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    
    log_info "Eliminando red..."
    docker network rm october_shared_network 2>/dev/null || true
    
    log_info "Limpiando volúmenes huérfanos..."
    docker volume prune -f
    
    log_info "Limpiando logs..."
    rm -rf "$LOG_DIR"/*
    
    log_info "✅ Limpieza completada"
}

cmd_update() {
    print_banner
    log_info "🔄 Actualizando imágenes Docker..."
    
    docker-compose -f "$COMPOSE_FILE" pull
    
    log_info "🔄 Recreando servicios con nuevas imágenes..."
    docker-compose -f "$COMPOSE_FILE" up -d --force-recreate
    
    log_info "✅ Actualización completada"
}

cmd_debug() {
    print_banner
    log_info "🔍 Información de debug:"
    echo
    
    echo -e "${BLUE}=== SISTEMA ===${NC}"
    echo "Docker version: $(docker --version)"
    echo "Docker Compose: $(docker-compose --version 2>/dev/null || docker compose version)"
    echo "SO: $(uname -a)"
    echo "Usuario: $(whoami)"
    echo
    
    echo -e "${BLUE}=== PROYECTO ===${NC}"
    echo "Script dir: $SCRIPT_DIR"
    echo "Project root: $PROJECT_ROOT"
    echo "Data dir: $DATA_DIR"
    echo "Compose file: $COMPOSE_FILE"
    echo
    
    echo -e "${BLUE}=== ARCHIVOS REQUERIDOS ===${NC}"
    local required_files=(
        "$COMPOSE_FILE"
        "$SCRIPT_DIR/nginx/nginx.conf"
        "$SCRIPT_DIR/nginx/sites/v3.conf"
        "$SCRIPT_DIR/nginx/sites/v4.conf"
        "$SCRIPT_DIR/database/init.sql"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "✅ $file"
        else
            echo "❌ $file"
        fi
    done
    echo
    
    echo -e "${BLUE}=== PUERTOS ===${NC}"
    echo "Puertos en uso:"
    netstat -tlnp 2>/dev/null | grep -E ":(80|443|5432|6379|8025|8080)" || echo "Ningún puerto relevante en uso"
}

show_help() {
    print_banner
    echo -e "${BLUE}USO:${NC}"
    echo "  $0 <comando> [opciones]"
    echo
    echo -e "${BLUE}COMANDOS PRINCIPALES:${NC}"
    echo "  start [profile]    Iniciar infraestructura (profile: development|production)"
    echo "  stop              Detener infraestructura"
    echo "  restart [profile] Reiniciar infraestructura"
    echo "  status            Mostrar estado de servicios"
    echo
    echo -e "${BLUE}LOGS Y MONITOREO:${NC}"
    echo "  logs [service]    Mostrar logs (sin service = todos)"
    echo "  logs service -f   Seguir logs en tiempo real"
    echo
    echo -e "${BLUE}BACKUP Y RESTORE:${NC}"
    echo "  backup            Crear backup completo"
    echo "  restore <path>    Restaurar desde backup"
    echo
    echo -e "${BLUE}MANTENIMIENTO:${NC}"
    echo "  clean             Limpiar todo (containers, volúmenes, red)"
    echo "  update            Actualizar imágenes Docker"
    echo "  debug             Información de debug"
    echo
    echo -e "${BLUE}EJEMPLOS:${NC}"
    echo "  $0 start                    # Iniciar con perfil development"
    echo "  $0 start production         # Iniciar sin MailHog/Adminer"
    echo "  $0 logs nginx-shared        # Ver logs de NGINX"
    echo "  $0 logs postgres-shared -f  # Seguir logs de PostgreSQL"
    echo "  $0 backup                   # Crear backup"
    echo "  $0 restore /path/to/backup  # Restaurar backup"
    echo
    echo -e "${BLUE}SERVICIOS DISPONIBLES:${NC}"
    echo "  - nginx-shared     (Puerto 80, 443)"
    echo "  - postgres-shared  (Puerto 5432)"
    echo "  - redis-shared     (Puerto 6379)"
    echo "  - mailhog-shared   (Puerto 1025, 8025) [development]"
    echo "  - adminer-shared   (Puerto 8080) [development]"
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
        "status")
            cmd_status "$@"
            ;;
        "logs")
            cmd_logs "$@"
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
        "debug")
            cmd_debug "$@"
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