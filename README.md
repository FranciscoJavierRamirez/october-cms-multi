# October CMS Multi-Version Development Environment

Un entorno de desarrollo Docker optimizado para ejecutar **October CMS v3.7** y **v4.0** simultáneamente, perfecto para pruebas de compatibilidad y migración.

## 🚀 Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone <repository-url>
cd october-cms-multi

# 2. Configuración inicial
make setup

# 3. Iniciar servicios
make up

# 4. Instalar October CMS
make install

# 5. ¡Listo! Acceder a:
# - October v3.7: http://v3.october.local
# - October v4.0: http://v4.october.local
```

## 📋 Requisitos

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Sistema**: Linux, macOS, o Windows con WSL2
- **RAM**: 4GB mínimo
- **Espacio**: 5GB libres

## 🏗️ Arquitectura

```
october-cms-multi/
├── docker-compose.yml       # Orquestación de servicios
├── Makefile                 # Comandos simplificados
├── .env.example             # Variables de entorno
├── containers/              # Dockerfiles
│   ├── october-v3/          # PHP 8.1 + October 3.7
│   └── october-v4/          # PHP 8.2 + October 4.0
├── config/                  # Configuraciones
│   ├── nginx/               # Virtual hosts
│   ├── postgres/            # Base de datos
│   └── redis/               # Cache
├── scripts/                 # Scripts auxiliares
└── volumes/                 # Datos persistentes
    ├── v3/                  # Código October v3.7
    ├── v4/                  # Código October v4.0
    └── data/                # PostgreSQL, Redis, logs
```

## 🛠️ Configuración

### 1. Configurar Hosts

Agregar a `/etc/hosts` (Linux/macOS) o `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 v3.october.local v4.october.local
```

### 2. Variables de Entorno

Copiar y ajustar si es necesario:

```bash
cp .env.example .env
```

### 3. Permisos (Linux/macOS)

```bash
chmod +x scripts/*.sh
```

## 📚 Comandos Disponibles

### Gestión de Servicios

```bash
make up         # Iniciar todos los servicios
make down       # Detener todos los servicios
make restart    # Reiniciar servicios
make status     # Ver estado
make logs       # Ver logs en tiempo real
```

### Instalación

```bash
make install      # Instalar ambas versiones
make install-v3   # Instalar solo v3.7
make install-v4   # Instalar solo v4.0
```

### Desarrollo

```bash
make shell-v3     # Acceder al shell de v3.7
make shell-v4     # Acceder al shell de v4.0
make logs-v3      # Ver logs de v3.7
make logs-v4      # Ver logs de v4.0
```

### Artisan Commands

```bash
make artisan-v3 CMD="make:plugin Acme.Blog"
make artisan-v4 CMD="migrate:fresh"
```

### Mantenimiento

```bash
make test       # Verificar servicios
make rebuild    # Reconstruir containers
make clean      # Limpiar todo (¡CUIDADO!)
```

## 🌐 URLs de Acceso

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **October v3.7** | http://v3.october.local | October CMS 3.7 (Laravel 10) |
| **October v4.0** | http://v4.october.local | October CMS 4.0 (Laravel 12) |
| **Adminer** | http://localhost:8080 | Gestión de base de datos |
| **MailHog** | http://localhost:8025 | Captura de emails |

## 🔑 Credenciales

### October CMS Admin
- **Email**: admin@localhost
- **Password**: admin123

### Base de Datos
- **Host**: localhost:5432
- **Usuario**: october_user
- **Password**: october_pass_2024
- **Database**: october_db

## 🧪 Pruebas de Compatibilidad

### Workflow Recomendado

1. **Desarrollar en v3.7**
   ```bash
   make shell-v3
   cd plugins/acme/demo
   # Desarrollar plugin...
   ```

2. **Copiar a v4.0**
   ```bash
   cp -r volumes/v3/plugins/acme volumes/v4/plugins/
   ```

3. **Probar en v4.0**
   ```bash
   make artisan-v4 CMD="plugin:refresh Acme.Demo"
   ```

4. **Verificar logs**
   ```bash
   make logs-v4
   ```

### Diferencias Clave

| Característica | v3.7 | v4.0 |
|----------------|------|------|
| **PHP** | 8.1 | 8.2 |
| **Laravel** | 10 | 12 |
| **Backend** | Clásico | Nuevo Dashboard |
| **Prefijo DB** | v3_ | v4_ |
| **Redis DB** | 0 | 1 |

## 🔧 Solución de Problemas

### Los hosts no funcionan

```bash
# Verificar hosts
ping v3.october.local

# Si falla, agregar manualmente:
sudo echo "127.0.0.1 v3.october.local v4.october.local" >> /etc/hosts
```

### Puerto ocupado

```bash
# Cambiar en .env
HTTP_PORT=8000
POSTGRES_PORT=5433
```

### Container no inicia

```bash
# Ver logs detallados

   **Accesos**

Para acceder al backend de October CMS v3.7:
URL de login: http://localhost/admin
Usuario: admin
Email: admin@example.com
Contraseña: password

