#!/bin/bash
# scripts/install.sh - Instalación de October CMS
set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

install_october() {
    local version=$1
    local container="october_${version}"
    local october_version
    local laravel_version

    case $version in
        v3)
            october_version="3.7.*"
            laravel_version="10"
            ;;
        v4)
            october_version="4.0.*"
            laravel_version="12"
            ;;
        *)
            error "Versión no válida: $version. Use 'v3' o 'v4'"
            ;;
    esac

    log "Instalando October CMS $version ($october_version)..."

    # Verificar que el container esté corriendo
    if ! docker ps | grep -q "${container}.*Up"; then
        error "Container $container no está corriendo. Ejecuta: make up"
    fi

    # Verificar si ya está instalado
    if docker exec "$container" test -f /var/www/html/artisan 2>/dev/null; then
        log "October CMS $version ya está instalado"
        return 0
    fi

    # Instalar October
    log "Descargando October CMS $october_version..."
    docker exec -w /var/www/html "$container" \
        composer create-project october/october . "$october_version" --prefer-dist --no-interaction

    # Configurar .env
    log "Configurando entorno..."
    docker exec "$container" bash -c "
        if [[ ! -f .env ]]; then
            cp .env.example .env
        fi
        
        # Actualizar configuración de base de datos
        sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=pgsql/' .env
        sed -i 's/DB_HOST=.*/DB_HOST=postgres/' .env
        sed -i 's/DB_PORT=.*/DB_PORT=5432/' .env
        sed -i 's/DB_DATABASE=.*/DB_DATABASE=october_shared/' .env
        sed -i 's/DB_USERNAME=.*/DB_USERNAME=october_user/' .env
        sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=october_pass_2024/' .env
        
        # Configurar Redis
        echo 'REDIS_HOST=redis' >> .env
        echo 'REDIS_PORT=6379' >> .env
        echo 'CACHE_STORE=redis' >> .env
        echo 'SESSION_DRIVER=redis' >> .env
        
        # Configurar Mail
        echo 'MAIL_HOST=mailhog' >> .env
        echo 'MAIL_PORT=1025' >> .env
    "

    # Generar key y migrar
    log "Generando application key..."
    docker exec "$container" php artisan key:generate

    log "Ejecutando migraciones..."
    docker exec "$container" php artisan october:migrate

    # Crear usuario admin
    log "Creando usuario administrador..."
    docker exec "$container" php artisan create:admin \
        --email="admin@localhost" \
        --password="admin123" \
        --first-name="Admin" \
        --last-name="User" || true

    # Optimizar para desarrollo
    log "Aplicando optimizaciones..."
    docker exec "$container" php artisan config:cache || true
    if [[ $version == "v4" ]]; then
        docker exec "$container" php artisan route:cache || true
    fi

    log "✅ Instalación de October CMS $version completada"
    echo ""
    echo "Credenciales de acceso:"
    echo "  URL:      http://${version}.october.local"
    echo "  Backend:  http://${version}.october.local/admin"
    echo "  Email:    admin@localhost"
    echo "  Password: admin123"
}

main() {
    local version=${1:-}
    
    if [[ -z $version ]]; then
        log "Instalando ambas versiones..."
        install_october "v3"
        install_october "v4"
    else
        install_october "$version"
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@" 