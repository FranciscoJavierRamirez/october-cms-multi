# October CMS Multi-Version Docker

Arquitectura Docker simplificada para ejecutar October CMS v3.7 y v4.0 simultáneamente.

## 🏗️ Arquitectura

```
shared/                 # Infraestructura compartida
├── nginx/             # NGINX como proxy reverso
├── postgres/          # PostgreSQL con esquemas separados
└── redis/             # Redis compartido

v3/                    # October CMS 3.7 (Laravel 10, PHP 8.1)
└── october/           # Código de la aplicación

v4/                    # October CMS 4.0 (Laravel 12, PHP 8.2)
└── october/           # Código de la aplicación
```

## 🚀 Inicio Rápido

```bash
# 1. Iniciar infraestructura compartida
cd shared && ./manage-shared.sh start

# 2. Iniciar October v3.7
cd ../v3 && ./manage-v3.sh start
./manage-v3.sh install

# 3. Iniciar October v4.0
cd ../v4 && ./manage-v4.sh start
./manage-v4.sh install
```

## 🌐 URLs de Acceso

- **October v3.7**: http://v3.october.local
- **October v4.0**: http://v4.october.local
- **Adminer**: http://localhost:8080
- **MailHog**: http://localhost:8025

Credenciales por defecto:
- Usuario: `admin@localhost`
- Password: `admin123`

## 📋 Comandos Disponibles

### Infraestructura Compartida
```bash
./shared/manage-shared.sh start    # Iniciar servicios
./shared/manage-shared.sh stop     # Detener servicios
./shared/manage-shared.sh status   # Ver estado
./shared/manage-shared.sh logs     # Ver logs
```

### October CMS (v3 y v4)
```bash
./v3/manage-v3.sh start           # Iniciar October v3.7
./v3/manage-v3.sh install         # Instalar October
./v3/manage-v3.sh artisan ...     # Ejecutar Artisan
./v3/manage-v3.sh composer ...    # Ejecutar Composer
./v3/manage-v3.sh shell           # Acceder al shell
```

### Control Maestro (opcional)
```bash
./master-control.sh start-all     # Iniciar todo
./master-control.sh stop-all      # Detener todo
./master-control.sh status        # Estado completo
```

## 🔧 Configuración

### Hosts
Agrega a `/etc/hosts`:
```
127.0.0.1 v3.october.local
127.0.0.1 v4.october.local
```

### Base de Datos
- **Host**: postgres-shared
- **Puerto**: 5432
- **Base de datos**: october_shared
- **Usuario**: october_user
- **Password**: october_shared_2024
- **Esquemas**:
  - v3.7: `october_v3` (prefix: `v3_`)
  - v4.0: `october_v4` (prefix: `v4_`)

## 📁 Estructura de Datos

```
data/
├── postgres/         # Datos PostgreSQL
├── redis/           # Datos Redis
├── nginx-logs/      # Logs NGINX
└── logs/
    ├── v3/          # Logs October v3.7
    └── v4/          # Logs October v4.0
```

## 🛠️ Desarrollo

### Crear un plugin
```bash
# Para v3.7
cd v3 && ./manage-v3.sh artisan make:plugin Acme.Blog

# Para v4.0
cd v4 && ./manage-v4.sh artisan make:plugin Acme.Blog
```

### Instalar paquetes
```bash
# Composer
./manage-v3.sh composer require vendor/package

# NPM (dentro del container)
./manage-v3.sh shell
npm install package
```

## 🧹 Limpieza

```bash
# Limpiar todo (CUIDADO: borra todos los datos)
./shared/manage-shared.sh clean
```

## 📋 Requisitos

- Docker 20+
- Docker Compose 2+
- 4GB RAM mínimo
- 10GB espacio en disco

## 🐛 Troubleshooting

### Container no inicia
```bash
# Verificar logs
docker-compose logs container-name

# Reiniciar servicios
./shared/manage-shared.sh restart
```

### Error de permisos
```bash
# Dentro del container
chown -R october:october /var/www/html
chmod -R 755 /var/www/html
```

### Base de datos no conecta
```bash
# Verificar que PostgreSQL esté corriendo
docker ps | grep postgres

# Test de conexión
docker exec postgres-shared pg_isready -U october_user
```
Estructura recomendada:
october-cms-multi/
├── v3/                    # ← Proyecto October v3.7 completo
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── .env
│   └── manage.sh
├── v4/                    # ← Proyecto October v4.0 completo  
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── .env
│   └── manage.sh
├── shared/                # ← Recursos compartidos opcionales
│   ├── themes/
│   ├── plugins/
│   └── database/
└── master-control.sh      # ← Script maestro (opcional)

**📝 Pasos para completar el setup**

Crear todos los archivos faltantes del artifact anterior
Ejecutar el script de setup:

chmod +x setup.sh
./setup.sh

Configurar hosts:
sudo echo "127.0.0.1 v3.october.local v4.october.local" >> /etc/hosts

Iniciar el sistema:

./master-control.sh start-all
./master-control.sh install-all