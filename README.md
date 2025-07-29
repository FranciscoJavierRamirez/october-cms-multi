# October CMS Multi-Version Development Environment

🚀 **Entorno de desarrollo completo y optimizado para ejecutar October CMS v3.7 y v4.0 simultáneamente con Docker.**

[![October CMS](https://img.shields.io/badge/October%20CMS-3.7%20%7C%204.0-blue)](https://octobercms.com/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue)](https://docker.com/)
[![PHP](https://img.shields.io/badge/PHP-8.1%20%7C%208.2-purple)](https://php.net/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)](https://postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-red)](https://redis.io/)

## ✨ Características

- **🔄 Multi-Versión**: October CMS v3.7 (Laravel 10) y v4.0 (Laravel 12) ejecutándose simultáneamente
- **🐳 Dockerizado**: Entorno completamente containerizado y aislado
- **🗄️ PostgreSQL**: Base de datos compartida con esquemas separados
- **⚡ Redis**: Cache y sesiones optimizadas
- **🌐 NGINX**: Servidor web optimizado con virtual hosts
- **📧 MailHog**: Captura de emails para desarrollo
- **💾 Adminer**: Interfaz web para gestión de base de datos
- **🛠️ Scripts**: Automatización completa de setup, instalación y validación

## 🏗️ Arquitectura

```
october-cms-multi/
├── docker-compose.yml           # Orquestación principal
├── Makefile                     # Comandos simplificados
├── env.example                  # Variables de entorno
├── scripts/                     # Scripts de automatización
│   ├── setup.sh                 # Configuración inicial
│   ├── install.sh               # Instalación de October
│   ├── validate.sh              # Validación del entorno
│   └── quick-start.sh           # Inicio rápido automatizado
├── config/                      # Configuraciones de servicios
│   ├── nginx/                   # Configuración NGINX
│   ├── postgres/                # Configuración PostgreSQL
│   └── redis/                   # Configuración Redis
├── containers/                  # Dockerfiles personalizados
│   ├── october-v3/              # Container October v3.7
│   └── october-v4/              # Container October v4.0
├── volumes/                     # Datos persistentes
│   ├── october-v3/              # Código October v3.7
│   ├── october-v4/              # Código October v4.0
│   └── data/                    # Datos de base de datos, logs
└── docs/                        # Documentación detallada
```

## 🚀 Inicio Rápido

### Opción 1: Script Automatizado (Recomendado)

```bash
git clone <repository-url>
cd october-cms-multi
./scripts/quick-start.sh
```

### Opción 2: Manual

```bash
# 1. Configuración inicial
make setup

# 2. Iniciar servicios
make up

# 3. Instalar October CMS
make install

# 4. Validar instalación
make validate
```

## 🌐 URLs de Acceso

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **October CMS v3.7** | http://v3.october.local | admin@localhost / admin123 |
| **October CMS v4.0** | http://v4.october.local | admin@localhost / admin123 |
| **Adminer** | http://localhost:8080 | october_user / october_pass_2024 |
| **MailHog** | http://localhost:8025 | - |

## 🛠️ Comandos Disponibles

```bash
# Gestión de servicios
make up               # Iniciar todos los servicios
make down             # Detener todos los servicios
make status           # Ver estado de servicios
make rebuild          # Reconstruir containers

# Instalación
make install          # Instalar ambas versiones
make install-v3       # Instalar solo October v3.7
make install-v4       # Instalar solo October v4.0

# Desarrollo
make shell-v3         # Acceder al shell de v3.7
make shell-v4         # Acceder al shell de v4.0
make logs             # Ver todos los logs
make logs-v3          # Ver logs de v3.7
make logs-v4          # Ver logs de v4.0

# Artisan Commands
make artisan-v3 CMD="make:plugin Acme.Blog"
make artisan-v4 CMD="make:plugin Acme.Blog"

# Utilidades
make validate         # Validar entorno
make clean            # Limpiar todo (¡CUIDADO!)
```

## 🔧 Requisitos del Sistema

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **RAM**: 4GB mínimo, 8GB recomendado
- **Almacenamiento**: 10GB libres
- **Sistema Operativo**: Linux, macOS, Windows (WSL2)

## 📊 Especificaciones Técnicas

### October CMS v3.7
- **PHP**: 8.1 con OPcache y JIT
- **Laravel**: 10
- **Base de datos**: PostgreSQL (prefijo `v3_`)
- **Cache**: Redis (database 0)
- **Backend**: Clásico

### October CMS v4.0
- **PHP**: 8.2 con JIT optimizado
- **Laravel**: 12
- **Base de datos**: PostgreSQL (prefijo `v4_`)
- **Cache**: Redis (database 1)
- **Backend**: Nuevo Dashboard

### Infraestructura
- **NGINX**: Alpine con configuraciones optimizadas
- **PostgreSQL**: 15 Alpine con configuración para desarrollo
- **Redis**: 7 Alpine con persistencia configurada

## 🔒 Seguridad

- Limitación de velocidad configurada en NGINX
- Headers de seguridad implementados
- Usuarios no privilegiados en containers
- Configuraciones de PHP endurecidas
- Aislamiento de red entre servicios

## 📚 Documentación

- [📖 Guía de Instalación](docs/INSTALL.md)
- [🎯 Guía de Uso](docs/USAGE.md)
- [🔧 Solución de Problemas](docs/TROUBLESHOOTING.md)

## 🐛 Solución de Problemas

### Problemas Comunes

**¿Los hosts no funcionan?**
```bash
# Agregar a /etc/hosts (Linux/macOS)
echo "127.0.0.1 v3.october.local v4.october.local" | sudo tee -a /etc/hosts
```

**¿Puertos ocupados?**
```bash
# Cambiar puertos en .env
HTTP_PORT=8000
POSTGRES_PORT=5433
```

**¿Containers no inician?**
```bash
# Ver logs detallados
make logs

# Reconstruir containers
make rebuild
```

## 🤝 Desarrollo

### Estructura de Desarrollo

```bash
# Trabajar con plugins
volumes/october-v3/plugins/acme/demo/
volumes/october-v4/plugins/acme/demo/

# Trabajar con temas
volumes/october-v3/themes/
volumes/october-v4/themes/
```

### Testing de Compatibilidad

1. Desarrollar en v3.7
2. Copiar plugin/tema a v4.0
3. Probar funcionalidad
4. Ajustar para compatibilidad

## 📈 Performance

### Optimizaciones Implementadas

- **PHP OPcache** con JIT habilitado
- **NGINX** con gzip y cache de assets
- **PostgreSQL** optimizado para desarrollo
- **Redis** como cache de aplicación y sesiones
- **Connection pooling** en upstreams

### Monitoreo

```bash
# Ver estadísticas de containers
docker stats

# Ver logs de performance
make logs | grep -i "slow\|error\|timeout"
```

## 🔄 Actualización

```bash
# Actualizar código
git pull origin main

# Reconstruir containers
make rebuild

# Validar cambios
make validate
```

## 🌟 Características Avanzadas

- **Hot Reload**: Cambios en código reflejados inmediatamente
- **Debug Tools**: Logs centralizados y debugging habilitado
- **Multi-Environment**: Configuración para desarrollo, staging y producción
- **Backup/Restore**: Scripts automatizados incluidos
- **Health Checks**: Verificación automática de servicios

## 📝 Changelog

### v2.0.0 (Actual)
- ✨ Arquitectura completamente reorganizada
- 🚀 Scripts de automatización mejorados
- 🏗️ Configuraciones optimizadas para performance
- 📚 Documentación completa actualizada
- 🛠️ Makefile simplificado
- 🐳 Dockerfiles optimizados para cada versión

### v1.0.0
- 🎯 Configuración inicial multi-versión
- 🐳 Containerización básica
- 📊 Servicios fundamentales

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/usuario/october-cms-multi/issues)
- **Email**: framirez@healthytek.cl
- **Documentación**: [Wiki del Proyecto](https://github.com/usuario/october-cms-multi/wiki)

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

**Desarrollado con ❤️ para la comunidad October CMS**