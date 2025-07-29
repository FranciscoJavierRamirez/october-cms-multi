#!/bin/bash
set -euo pipefail

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo -e "${BLUE}"
echo "██████╗  ██████╗████████╗ ██████╗ ██████╗ ███████╗██████╗ "
echo "██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗"
echo "██║  ██║██║        ██║   ██║   ██║██████╔╝█████╗  ██████╔╝"
echo "██║  ██║██║        ██║   ██║   ██║██╔══██╗██╔══╝  ██╔══██╗"
echo "██████╔╝╚██████╗   ██║   ╚██████╔╝██████╔╝███████╗██║  ██║"
echo "╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${BLUE}October CMS Multi-Version Development Environment${NC}"
echo -e "${BLUE}Quick Start Script${NC}"
echo ""

main() {
    echo -e "${GREEN}🚀 Iniciando configuración automática...${NC}"
    echo ""

    # Verificar dependencias
    echo "1️⃣ Verificando dependencias..."
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${YELLOW}❌ Docker no encontrado. Instálalo desde: https://docs.docker.com/install/${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${YELLOW}❌ Docker Compose no encontrado${NC}"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}❌ Docker daemon no está corriendo${NC}"
        exit 1
    fi
    
    echo "✅ Docker y Docker Compose encontrados"

    # Configuración inicial
    echo ""
    echo "2️⃣ Configuración inicial..."
    if [[ ! -f .env ]]; then
        cp env.example .env
        echo "✅ Archivo .env creado"
    else
        echo "✅ Archivo .env ya existe"
    fi

    # Permisos
    find scripts/ -name "*.sh" -type f -exec chmod +x {} \;
    echo "✅ Permisos de scripts configurados"

    # Hosts
    echo ""
    echo "3️⃣ Configurando hosts..."
    if ! grep -q "v3.october.local" /etc/hosts 2>/dev/null; then
        echo -e "${YELLOW}⚠️ Los hosts no están configurados${NC}"
        echo ""
        echo "Para continuar, necesitas agregar estas líneas a /etc/hosts:"
        echo "127.0.0.1 v3.october.local v4.october.local"
        echo ""
        read -p "¿Deseas que lo configure automáticamente? (requiere sudo) [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "127.0.0.1 v3.october.local v4.october.local" | sudo tee -a /etc/hosts >/dev/null
            echo "✅ Hosts configurados automáticamente"
        else
            echo -e "${YELLOW}⚠️ Configura los hosts manualmente y ejecuta el script de nuevo${NC}"
            exit 1
        fi
    else
        echo "✅ Hosts ya configurados"
    fi

    # Iniciar servicios
    echo ""
    echo "4️⃣ Iniciando servicios..."
    docker-compose up -d
    echo "✅ Servicios iniciados"

    # Esperar a que los servicios estén listos
    echo ""
    echo "5️⃣ Esperando servicios..."
    local timeout=60
    local counter=0
    
    while ! docker exec october_postgres pg_isready -U october_user >/dev/null 2>&1; do
        counter=$((counter + 1))
        if [[ $counter -gt $timeout ]]; then
            echo -e "${YELLOW}❌ Timeout esperando PostgreSQL${NC}"
            exit 1
        fi
        echo "Esperando PostgreSQL... ($counter/$timeout)"
        sleep 1
    done
    echo "✅ PostgreSQL listo"

    # Instalar October CMS
    echo ""
    echo "6️⃣ Instalando October CMS..."
    echo "📦 Instalando October v3.7..."
    ./scripts/install.sh v3

    echo ""
    echo "📦 Instalando October v4.0..."
    ./scripts/install.sh v4

    # Validación final
    echo ""
    echo "7️⃣ Validando instalación..."
    if ./scripts/validate.sh >/dev/null 2>&1; then
        echo "✅ Validación exitosa"
    else
        echo -e "${YELLOW}⚠️ Algunos servicios pueden necesitar más tiempo${NC}"
    fi

    # Resultado final
    echo ""
    echo -e "${GREEN}🎉 ¡Instalación completada exitosamente!${NC}"
    echo ""
    echo -e "${BLUE}URLs de acceso:${NC}"
    echo "  📱 October v3.7: http://v3.october.local"
    echo "  📱 October v4.0: http://v4.october.local"
    echo "  🗄️ Adminer:      http://localhost:8080"
    echo "  📧 MailHog:      http://localhost:8025"
    echo ""
    echo -e "${BLUE}Credenciales de admin:${NC}"
    echo "  📧 Email:    admin@localhost"
    echo "  🔐 Password: admin123"
    echo ""
    echo -e "${BLUE}Comandos útiles:${NC}"
    echo "  make status     # Ver estado de servicios"
    echo "  make logs       # Ver logs"
    echo "  make validate   # Validar entorno"
    echo "  make down       # Detener servicios"
    echo ""
    echo -e "${GREEN}¡Listo para desarrollar! 🚀${NC}"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@" 