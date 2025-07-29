#!/bin/bash
# validate.sh - Validación completa del entorno

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        ((FAILED++))
        return 1
    fi
}

check_version() {
    local current="$1"
    local required="$2"
    local name="$3"
    
    if [ "$(printf '%s\n' "$required" "$current" | sort -V | head -n1)" = "$required" ]; then
        echo -e "${GREEN}✓${NC} $name version $current (>= $required)"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name version $current (requiere >= $required)"
        ((FAILED++))
    fi
}

echo -e "${BLUE}=== Validación Completa del Entorno October CMS ===${NC}"
echo ""

# Docker y dependencias
echo "SISTEMA Y DEPENDENCIAS:"
docker --version >/dev/null 2>&1 && check "Docker instalado" || check "Docker instalado"

if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    check_version "$DOCKER_VERSION" "20.0" "Docker"
fi

docker-compose --version >/dev/null 2>&1 && check "Docker Compose instalado" || check "Docker Compose instalado"

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    check_version "$COMPOSE_VERSION" "2.0" "Docker Compose"
fi

docker info >/dev/null 2>&1 && check "Docker daemon funcionando" || check "Docker daemon funcionando"

# Red Docker
echo ""
echo "REDES DOCKER:"
docker network ls | grep -q "october_shared_network" && check "Red october_shared_network existe" || check "Red october_shared_network existe"

# Servicios compartidos
echo ""
echo "SERVICIOS COMPARTIDOS:"
docker ps | grep -q "october_postgres_shared.*Up" && check "PostgreSQL corriendo" || check "PostgreSQL corriendo"
docker ps | grep -q "october_redis_shared.*Up" && check "Redis corriendo" || check "Redis corriendo"
docker ps | grep -q "october_nginx_shared.*Up" && check "NGINX corriendo" || check "NGINX corriendo"
docker ps | grep -q "october_mailhog_shared.*Up" && check "MailHog corriendo" || check "MailHog corriendo"

# Verificar conectividad a servicios
if docker ps | grep -q "october_postgres_shared.*Up"; then
    docker exec october_postgres_shared pg_isready -U october_user >/dev/null 2>&1 && check "PostgreSQL respondiendo" || check "PostgreSQL respondiendo"
fi

if docker ps | grep -q "october_redis_shared.*Up"; then
    docker exec october_redis_shared redis-cli ping >/dev/null 2>&1 && check "Redis respondiendo" || check "Redis respondiendo"
fi

# October instances
echo ""
echo "INSTANCIAS OCTOBER:"
docker ps | grep -q "october_v3_app.*Up" && check "October v3.7 container corriendo" || check "October v3.7 container corriendo"
docker ps | grep -q "october_v4_app.*Up" && check "October v4.0 container corriendo" || check "October v4.0 container corriendo"

# Verificar instalación
if docker ps | grep -q "october_v3_app.*Up"; then
    docker exec october_v3_app test -f /var/www/html/artisan 2>/dev/null && check "October v3.7 instalado" || check "October v3.7 instalado"
fi

if docker ps | grep -q "october_v4_app.*Up"; then
    docker exec october_v4_app test -f /var/www/html/artisan 2>/dev/null && check "October v4.0 instalado" || check "October v4.0 instalado"
fi

# Hosts configuration
echo ""
echo "CONFIGURACIÓN DE HOSTS:"
grep -q "v3.october.local" /etc/hosts 2>/dev/null && check "v3.october.local en /etc/hosts" || check "v3.october.local en /etc/hosts"
grep -q "v4.october.local" /etc/hosts 2>/dev/null && check "v4.october.local en /etc/hosts" || check "v4.october.local en /etc/hosts"

# Conectividad HTTP
echo ""
echo "CONECTIVIDAD HTTP:"
if grep -q "v3.october.local" /etc/hosts 2>/dev/null; then
    curl -s -o /dev/null -w "%{http_code}" http://v3.october.local 2>/dev/null | grep -q "200\|302" && check "v3.october.local accesible" || check "v3.october.local accesible"
fi

if grep -q "v4.october.local" /etc/hosts 2>/dev/null; then
    curl -s -o /dev/null -w "%{http_code}" http://v4.october.local 2>/dev/null | grep -q "200\|302" && check "v4.october.local accesible" || check "v4.october.local accesible"
fi

curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200" && check "Adminer accesible" || check "Adminer accesible"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8025 2>/dev/null | grep -q "200" && check "MailHog accesible" || check "MailHog accesible"

# Espacio en disco
echo ""
echo "RECURSOS DEL SISTEMA:"
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ "$AVAILABLE_SPACE" =~ ^[0-9]+$ ]] && [ "$AVAILABLE_SPACE" -ge 10 ]; then
    echo -e "${GREEN}✓${NC} Espacio en disco: ${AVAILABLE_SPACE}GB disponibles"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Espacio en disco: ${AVAILABLE_SPACE}GB (se recomiendan 10GB+)"
    ((FAILED++))
fi

# Memoria disponible
if command -v free >/dev/null 2>&1; then
    AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
    if [ "$AVAILABLE_MEM" -ge 2048 ]; then
        echo -e "${GREEN}✓${NC} Memoria disponible: ${AVAILABLE_MEM}MB"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Memoria disponible: ${AVAILABLE_MEM}MB (se recomiendan 2048MB+)"
        ((FAILED++))
    fi
fi

# Directorios y permisos
echo ""
echo "ESTRUCTURA DE ARCHIVOS:"
[ -d "data/postgres" ] && check "Directorio data/postgres existe" || check "Directorio data/postgres existe"
[ -d "data/redis" ] && check "Directorio data/redis existe" || check "Directorio data/redis existe"
[ -d "v3/october" ] && check "Directorio v3/october existe" || check "Directorio v3/october existe"
[ -d "v4/october" ] && check "Directorio v4/october existe" || check "Directorio v4/october existe"

# Archivos de configuración
[ -f "v3/.env" ] && check "Archivo v3/.env existe" || check "Archivo v3/.env existe"
[ -f "v4/.env" ] && check "Archivo v4/.env existe" || check "Archivo v4/.env existe"

# Scripts ejecutables
[ -x "master-control.sh" ] && check "master-control.sh es ejecutable" || check "master-control.sh es ejecutable"
[ -x "shared/manage-shared.sh" ] && check "manage-shared.sh es ejecutable" || check "manage-shared.sh es ejecutable"
[ -x "v3/manage-v3.sh" ] && check "manage-v3.sh es ejecutable" || check "manage-v3.sh es ejecutable"
[ -x "v4/manage-v4.sh" ] && check "manage-v4.sh es ejecutable" || check "manage-v4.sh es ejecutable"

# Resumen
echo ""
echo -e "${BLUE}=== RESUMEN ===${NC}"
echo -e "Pruebas pasadas: ${GREEN}$PASSED${NC}"
echo -e "Pruebas fallidas: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ¡Todo está funcionando correctamente!${NC}"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠ Hay problemas que resolver${NC}"
    echo ""
    echo "Sugerencias:"
    if ! docker ps | grep -q "october_.*_shared.*Up"; then
        echo "- Iniciar servicios compartidos: cd shared && ./manage-shared.sh start"
    fi
    if ! docker ps | grep -q "october_v3_app.*Up"; then
        echo "- Iniciar October v3.7: cd v3 && ./manage-v3.sh start"
    fi
    if ! docker ps | grep -q "october_v4_app.*Up"; then
        echo "- Iniciar October v4.0: cd v4 && ./manage-v4.sh start"
    fi
    if ! grep -q "october.local" /etc/hosts 2>/dev/null; then
        echo "- Configurar hosts: sudo echo '127.0.0.1 v3.october.local v4.october.local' >> /etc/hosts"
    fi
    exit 1
fi