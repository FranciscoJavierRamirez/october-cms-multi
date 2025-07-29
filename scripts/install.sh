#!/bin/bash
set -euo pipefail

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para instalar October
install_october() {
    local version=$1
    local container="october_${version}"
    local october_version
    
    case $version in
        v3)
            october_version="3.7.*"
            ;;
        v4)
            october_version="4.0.*"
            ;;
        *)
            echo "Versión no válida: $version"
            exit 1
            ;;
    esac
    
    echo -e "${BLUE}Instalando October CMS ${version} (${october_version})...${NC}"
    
    # Verificar si ya está instalado
    if docker exec $container test -f /var/www/html/artisan 2>/dev/null; then
        echo -e "${YELLOW}October ${version} ya está instalado${NC}"
        return 0
    fi
    
    # Instalar October
    echo "Descargando October CMS..."
    docker exec -u october $container composer create-project october/october . "$october_version" --prefer-dist --no-interaction
    
    # Configurar .env
    echo "Configurando entorno..."
    docker exec -u october $container cp .env.example .env
    
    # Actualizar configuración
    docker exec -u october $container sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=pgsql/' .env
    docker exec -u october $container sed -i 's/DB_HOST=.*/DB_HOST=postgres/' .env
    docker exec -u october $container sed -i 's/DB_PORT=.*/DB_PORT=5432/' .env
    docker exec -u october $container sed -i 's/DB_DATABASE=.*/DB_DATABASE=october_db/' .env
    docker exec -u october $container sed -i 's/DB_USERNAME=.*/DB_USERNAME=october_user/' .env
    docker exec -u october $container sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=october_pass_2024/' .env
    
    # Configurar prefijo de tabla según versión
    if [ "$version" == "v3" ]; then
        docker exec -u october $container sed -i 's/DB_PREFIX=.*/DB_PREFIX=v3_/' .env
    else
        docker exec -u october $container sed -i 's/DB_PREFIX=.*/DB_PREFIX=v4_/' .env
    fi
    
    # Generar key
    echo "Generando application key..."
    docker exec -u october $container php artisan key:generate
    
    # Migrar base de datos
    echo "Ejecutando migraciones..."
    docker exec -u october $container php artisan october:migrate
    
    # Crear usuario admin
    echo "Creando usuario administrador..."
    docker exec -u october $container php artisan create:admin \
        --email="admin@localhost" \
        --password="admin123" \
        --first-name="Admin" \
        --last-name="User" || true
    
    echo -e "${GREEN}✓ October ${version} instalado correctamente${NC}"
    echo ""
}

# Main
main() {
    if [ $# -eq 0 ]; then
        # Instalar ambas versiones
        install_october "v3"
        install_october "v4"
        
        echo -e "${GREEN}✓ Instalación completada${NC}"
        echo ""
        echo "URLs de acceso:"
        echo "  October v3.7: http://v3.october.local"
        echo "  October v4.0: http://v4.october.local"
        echo ""
        echo "Credenciales:"
        echo "  Email: admin@localhost"
        echo "  Password: admin123"
    else
        # Instalar versión específica
        install_october "$1"
    fi
}

main "$@"