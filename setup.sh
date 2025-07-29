# 15. Setup script para permisos
#!/bin/bash
# setup.sh - Script inicial de configuración

echo "Configurando proyecto October CMS Multi-Version..."

# Dar permisos de ejecución a todos los scripts
chmod +x master-control.sh
chmod +x shared/manage-shared.sh
chmod +x v3/manage-v3.sh
chmod +x v4/manage-v4.sh
chmod +x v3/scripts/*.sh
chmod +x v4/scripts/*.sh

# Crear estructura de directorios
mkdir -p data/{postgres,redis,nginx-logs,logs/{v3,v4},composer-v3,composer-v4,ssl}
mkdir -p v3/{october,config/{php,supervisor},scripts}
mkdir -p v4/{october,config/{php,supervisor},scripts}
mkdir -p shared/{nginx/sites,database,redis}

# Copiar archivos de ejemplo
[ -f "v3/.env.example" ] && cp v3/.env.example v3/.env
[ -f "v4/.env.example" ] && cp v4/.env.example v4/.env

echo "✓ Permisos configurados"
echo "✓ Directorios creados"
echo ""
echo "Próximos pasos:"
echo "1. Editar archivos /etc/hosts"
echo "2. cd shared && ./manage-shared.sh start"
echo "3. cd ../v3 && ./manage-v3.sh start && ./manage-v3.sh install"
echo "4. cd ../v4 && ./manage-v4.sh start && ./manage-v4.sh install"