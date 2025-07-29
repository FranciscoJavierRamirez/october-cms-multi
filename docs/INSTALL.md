# Guía de Instalación October CMS Multi-Version

## Requisitos Previos

### 1. Docker y Docker Compose

**Ubuntu/Debian:**
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reiniciar sesión
newgrp docker
```

**macOS:**
```bash
# Instalar Docker Desktop
brew install --cask docker

# O descargar desde: https://www.docker.com/products/docker-desktop
```

**Windows:**
1. Instalar Docker Desktop desde https://www.docker.com/products/docker-desktop
2. Habilitar WSL2
3. Reiniciar sistema

### 2. Verificar Instalación

```bash
docker --version
docker-compose --version
docker info
```

## Instalación Paso a Paso

### 1. Obtener el Código

```bash
git clone <repository-url>
cd october-cms-multi
```

### 2. Configuración Inicial

```bash
# Ejecutar setup automático
make setup

# O manual:
cp env.example .env
chmod +x scripts/*.sh
```

### 3. Configurar Hosts

**Linux/macOS:**
```bash
sudo echo "127.0.0.1 v3.october.local v4.october.local" >> /etc/hosts
```

**Windows (como Administrador):**
```cmd
echo 127.0.0.1 v3.october.local v4.october.local >> C:\Windows\System32\drivers\etc\hosts
```

### 4. Iniciar Servicios

```bash
# Iniciar infraestructura
make up

# Verificar estado
make status
```

### 5. Instalar October CMS

```bash
# Instalar ambas versiones
make install

# Verificar instalación
make validate
```

## Verificación Final

✅ **URLs funcionando:**
- http://v3.october.local
- http://v4.october.local
- http://localhost:8080 (Adminer)
- http://localhost:8025 (MailHog)

✅ **Credenciales:**
- Usuario: admin@localhost
- Password: admin123 