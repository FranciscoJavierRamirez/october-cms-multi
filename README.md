# 🏗️ Arquitectura October CMS - Scripts Separados

## 📁 Estructura del Proyecto

```
october-cms-multi/
├── shared/                          # Infraestructura compartida
│   ├── docker-compose.yml         # NGINX + PostgreSQL + Redis
│   ├── nginx/
│   │   ├── nginx.conf             # Configuración principal
│   │   └── sites/
│   │       ├── v3.conf            # Virtual host v3.7
│   │       └── v4.conf            # Virtual host v4.0
│   ├── database/
│   │   └── init.sql               # Inicialización DB
│   └── manage-shared.sh           # Gestión infraestructura
├── v3/                             # October CMS v3.7 independiente
│   ├── Dockerfile                 # Imagen v3.7 minimalista
│   ├── docker-compose.yml         # Solo aplicación v3.7
│   ├── .env                       # Variables v3.7
│   ├── manage-v3.sh               # Control v3.7
│   └── october/                   # Código October v3.7
├── v4/                             # October CMS v4.0 independiente
│   ├── Dockerfile                 # Imagen v4.0 minimalista
│   ├── docker-compose.yml         # Solo aplicación v4.0
│   ├── .env                       # Variables v4.0
│   ├── manage-v4.sh               # Control v4.0
│   └── october/                   # Código October v4.0
├── data/                           # Datos persistentes
│   ├── postgres/                  # Base de datos compartida
│   ├── nginx-logs/                # Logs NGINX
│   └── uploads/                   # Uploads compartidos (opcional)
└── master-control.sh              # Control maestro (opcional)
```

## 🔗 **Infraestructura Compartida**

### **Servicios Compartidos (shared/docker-compose.yml):**
- **🌐 NGINX**: Proxy reverso con virtual hosts
- **🐘 PostgreSQL**: Base de datos para ambas versiones
- **🔴 Redis**: Cache compartido
- **📧 MailHog**: Servidor correo desarrollo

### **Aplicaciones Independientes:**
- **📦 October v3.7**: Container separado
- **📦 October v4.0**: Container separado

## 🎯 **Beneficios de esta Arquitectura**

### ✅ **Infraestructura Compartida:**
- **Una sola base de datos** con esquemas separados
- **Un solo NGINX** con virtual hosts
- **Recursos optimizados** (menos memoria/CPU)
- **Logs centralizados**

### ✅ **Aplicaciones Independientes:**
- **Encender/apagar** cada versión por separado
- **Desarrollo independiente** sin interferencias
- **Deploy independiente** a producción
- **Testing aislado** de cada versión

### ✅ **Flexibilidad Máxima:**
```bash
# Solo infraestructura
./shared/manage-shared.sh start

# Solo October v3.7
./v3/manage-v3.sh start

# Solo October v4.0  
./v4/manage-v4.sh start

# Ambas versiones
./master-control.sh start-all

# Comparación lado a lado
./master-control.sh compare
```

## 🌐 **Configuración NGINX Compartido**

### **Virtual Hosts:**
- **v3.october.local** → October v3.7 (puerto 8037)
- **v4.october.local** → October v4.0 (puerto 8040)
- **october.local** → Panel selector

### **Proxy Configuration:**
```nginx
# v3.october.local → october-v3:80
upstream october_v3 {
    server october-v3:80;
}

# v4.october.local → october-v4:80  
upstream october_v4 {
    server october-v4:80;
}
```

## 🗄️ **PostgreSQL Compartido**

### **Esquemas Separados:**
```sql
-- Base de datos: october_shared
-- Esquema v3: october_v3.*
-- Esquema v4: october_v4.*

CREATE SCHEMA october_v3;
CREATE SCHEMA october_v4;
```

### **Configuración por Versión:**
```bash
# v3.7
DB_PREFIX=v3_
DB_SCHEMA=october_v3

# v4.0  
DB_PREFIX=v4_
DB_SCHEMA=october_v4
```

## 🚀 **Casos de Uso**

### **Desarrollo Normal:**
```bash
# 1. Levantar infraestructura
cd shared && ./manage-shared.sh start

# 2. Desarrollar solo en v3.7
cd ../v3 && ./manage-v3.sh start

# 3. Probar algo en v4.0
cd ../v4 && ./manage-v4.sh start
```

### **Testing de Migración:**
```bash
# 1. Infraestructura compartida
cd shared && ./manage-shared.sh start

# 2. Ambas versiones
cd ../v3 && ./manage-v3.sh start
cd ../v4 && ./manage-v4.sh start

# 3. Comparar lado a lado
open http://v3.october.local
open http://v4.october.local
```

### **Producción Individual:**
```bash
# Solo v3.7 en producción
cd shared && ./manage-shared.sh start
cd ../v3 && ./manage-v3.sh start

# O solo v4.0 en producción
cd shared && ./manage-shared.sh start  
cd ../v4 && ./manage-v4.sh start
```

## 🎯 **Próximos Pasos**

1. **Crear infraestructura compartida** (shared/)
2. **Dockerfiles minimalistas** para v3.7 y v4.0
3. **Scripts de gestión** independientes
4. **Script maestro** para orquestación
5. **Testing** de la arquitectura completa


## 🎯 **Uso script manage-shared.sh**

El script manage-shared.sh completo para gestionar la infraestructura compartida. Este script incluye todas las funcionalidades necesarias:
🎯 Características Principales:
📋 Comandos Disponibles:

start [profile] - Iniciar infraestructura (development/production)
stop - Detener servicios
restart - Reiniciar servicios
status - Estado completo del sistema
logs [service] [-f] - Ver logs (con opción follow)
backup - Backup automático con timestamp
restore <path> - Restaurar desde backup
clean - Limpieza completa
update - Actualizar imágenes Docker
debug - Información de troubleshooting

🛠️ Funcionalidades Técnicas:

Verificación de dependencias (Docker, permisos)
Creación automática de directorios de datos
Gestión de red Docker compartida
Health checks para todos los servicios
Inicio secuencial (DB primero, luego web)
Backups completos (PostgreSQL por esquemas, Redis, configs)
Colores y logging estructurado
Perfiles development/production

💾 Sistema de Backup:

Backup completo de PostgreSQL (full + por esquemas)
Backup de Redis
Backup de configuraciones NGINX
Información detallada del backup
Restore con confirmación de seguridad

🔍 Monitoreo y Debug:

Estado de todos los containers
Health checks específicos por servicio
URLs de acceso directo
Información del sistema
Verificación de archivos requeridos

📝 Uso del Script:
# Hacer ejecutable
chmod +x shared/manage-shared.sh

# Iniciar infraestructura para desarrollo
./shared/manage-shared.sh start

# Ver estado completo
./shared/manage-shared.sh status

# Ver logs de NGINX en tiempo real
./shared/manage-shared.sh logs nginx-shared -f

# Crear backup
./shared/manage-shared.sh backup

# Ayuda completa
./shared/manage-shared.sh help


## 🎯 **Uso script manage-v3.sh**


🎯 Características Principales:
📋 Comandos Disponibles:

start - Iniciar October v3.7 (verifica infraestructura compartida)
stop/restart - Control del container
install - Instalación automática completa de October v3.7
status - Estado detallado con health checks
artisan <cmd> - Proxy para comandos Artisan
composer <cmd> - Proxy para comandos Composer
shell - Acceso directo al container
logs [-f] - Visualización de logs
backup/restore - Sistema completo de backup
clean - Limpieza total (files, DB schema, logs)
update - Actualización de October y dependencias

🛠️ Funcionalidades Técnicas:
Verificaciones Inteligentes:

Dependencias del sistema (Docker, Docker Compose)
Estado de infraestructura compartida (red, PostgreSQL, Redis)
Estado de instalación de October
Health checks de PHP-FPM, DB y Redis

Instalación Automática:
./v3/manage-v3.sh install

Descarga October v3.7 via Composer
Configura .env automáticamente
Ejecuta migraciones
Crea usuario admin (admin-v3@localhost / admin123v3)
Instala Builder Plugin
Configura permisos correctos

Sistema de Backup Específico:

Backup solo del esquema october_v3 (no afecta v4)
Backup de archivos de aplicación comprimidos
Backup de configuraciones (.env, docker-compose)
Restore selectivo con confirmación
Información detallada del backup

Integración con Infraestructura Compartida:

Verifica automáticamente que la infraestructura esté corriendo
Usa la red Docker compartida october_shared_network
Conecta a PostgreSQL y Redis compartidos
Esquema de DB separado (october_v3)
Logs independientes en /data/logs/v3

⚙️ Configuración Automática:
Variables de Entorno (.env):

# Se crea automáticamente con:
- October v3.7 específico
- Laravel 10
- PHP 8.1
- Conexión a infraestructura compartida
- Configuración de admin predefinida
- Builder Plugin habilitado

Comandos de Desarrollo:

# Artisan commands
./v3/manage-v3.sh artisan october:version
./v3/manage-v3.sh artisan make:plugin Author.Plugin
./v3/manage-v3.sh artisan october:migrate

# Composer operations
./v3/manage-v3.sh composer require vendor/package
./v3/manage-v3.sh composer update

# Shell access
./v3/manage-v3.sh shell

🔍 Status y Monitoreo:

./v3/manage-v3.sh status

Muestra:

Estado del container
Versión de October instalada
Lista de plugins
Health checks (PHP-FPM, DB, Redis)
URLs de acceso
Credenciales de admin

💾 Backup y Restore:
# Crear backup
./v3/manage-v3.sh backup

# Listar backups disponibles
./v3/manage-v3.sh restore
# └── Muestra: /data/backups/v3/v3_20250728_143022/

# Restaurar backup específico
./v3/manage-v3.sh restore /path/to/backup

📝 Flujo de Uso Típico:
# 1. Iniciar infraestructura compartida
cd shared && ./manage-shared.sh start

# 2. Iniciar October v3.7
cd ../v3 && ./manage-v3.sh start

# 3. Instalar October (primera vez)
./manage-v3.sh install

# 4. Verificar estado
./manage-v3.sh status

# 5. Desarrollo
./manage-v3.sh artisan make:plugin MyAuthor.MyPlugin
./manage-v3.sh shell

🌐 URLs de Acceso:

Frontend: http://v3.october.local
Backend: http://v3.october.local/admin
Admin: admin-v3@localhost / admin123v3

🔗 Integración con Infraestructura:
El script está diseñado para trabajar solo cuando la infraestructura compartida está activa. Si no está corriendo, te guía automáticamente:

[ERROR] PostgreSQL compartido no está corriendo
[WARN] Ejecuta: /path/to/shared/manage-shared.sh start