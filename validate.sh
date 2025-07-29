#!/bin/bash
# validate.sh - Validación del entorno

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

echo "=== Validación del entorno October CMS ==="
echo ""

# Docker
echo "DOCKER:"
docker --version >/dev/null 2>&1 && check "Docker instalado" || check "Docker instalado"
docker info >/dev/null 2>&1 && check "Docker funcionando" || check "Docker funcionando"

# Servicios compartidos
echo ""
echo "SERVICIOS COMPARTIDOS:"
docker ps | grep -q "october_postgres_shared.*Up" && check "PostgreSQL corriendo" || check "PostgreSQL corriendo"
docker ps | grep -q "october_redis_shared.*Up" && check "Redis corriendo" || check "Redis corriendo"
docker ps | grep -q "october_nginx_shared.*Up" && check "NGINX corriendo" || check "NGINX corriendo"

# October instances
echo ""
echo "INSTANCIAS OCTOBER:"
docker ps | grep -q "october_v3_app.*Up" && check "October v3.7 corriendo" || check "October v3.7 corriendo"
docker ps | grep -q "october_v4_app.*Up" && check "October v4.0 corriendo" || check "October v4.0 corriendo"

# Conectividad
echo ""
echo "CONECTIVIDAD:"
curl -s -o /dev/null -w "%{http_code}" http://v3.october.local 2>/dev/null | grep -q "200\|302" && check "v3.october.local accesible" || check "v3.october.local accesible"
curl -s -o /dev/null -w "%{http_code}" http://v4.october.local 2>/dev/null | grep -q "200\|302" && check "v4.october.local accesible" || check "v4.october.local accesible"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200" && check "Adminer accesible" || check "Adminer accesible"

echo ""
echo "=== Validación completada ==="