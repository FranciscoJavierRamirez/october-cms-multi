#!/bin/bash
# fix-permissions.sh - Corrige permisos de ejecución en todos los scripts

set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Corrigiendo permisos de scripts...${NC}"

# Encontrar y dar permisos a todos los scripts .sh
find . -name "*.sh" -type f -exec chmod +x {} \;

# Listar scripts actualizados
echo -e "${GREEN}Scripts con permisos actualizados:${NC}"
find . -name "*.sh" -type f -exec ls -la {} \;

echo -e "${GREEN}✅ Permisos corregidos${NC}"