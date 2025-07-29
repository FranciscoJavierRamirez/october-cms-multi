#!/bin/bash
# scripts/validate.sh - Validación del entorno
set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

PASSED=0
FAILED=0

check() {
    if eval "$2" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $1"
        ((FAILED++))
    fi
}

check_url() {
    local name=$1
    local url=$2
    if curl -sf "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name accesible"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name no accesible"
        ((FAILED++))
    fi
}

main() {
    echo "=== Validación del Entorno October CMS ==="
    echo ""

    echo "DEPENDENCIAS:"
    check "Docker instalado" "command -v docker"
    check "Docker Compose instalado" "command -v docker-compose"
    check "Docker funcionando" "docker info"

    echo ""
    echo "SERVICIOS:"
    check "PostgreSQL corriendo" "docker ps | grep -q 'october_postgres.*Up'"
    check "Redis corriendo" "docker ps | grep -q 'october_redis.*Up'"
    check "NGINX corriendo" "docker ps | grep -q 'october_nginx.*Up'"
    check "October v3 corriendo" "docker ps | grep -q 'october_v3.*Up'"
    check "October v4 corriendo" "docker ps | grep -q 'october_v4.*Up'"

    echo ""
    echo "INSTALACIONES:"
    check "October v3 instalado" "docker exec october_v3 test -f /var/www/html/artisan"
    check "October v4 instalado" "docker exec october_v4 test -f /var/www/html/artisan"

    echo ""
    echo "CONECTIVIDAD:"
    check "PostgreSQL respondiendo" "docker exec october_postgres pg_isready -U october_user"
    check "Redis respondiendo" "docker exec october_redis redis-cli ping"

    if grep -q "october.local" /etc/hosts 2>/dev/null; then
        check_url "October v3.7" "http://v3.october.local"
        check_url "October v4.0" "http://v4.october.local"
    fi
    
    check_url "Adminer" "http://localhost:8080"
    check_url "MailHog" "http://localhost:8025"

    echo ""
    echo "=== RESUMEN ==="
    echo -e "Pasadas: ${GREEN}$PASSED${NC}"
    echo -e "Fallidas: ${RED}$FAILED${NC}"

    if [[ $FAILED -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✅ Todo funcionando correctamente${NC}"
        exit 0
    else
        echo ""
        echo -e "${YELLOW}⚠ Hay problemas que resolver${NC}"
        exit 1
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@" 