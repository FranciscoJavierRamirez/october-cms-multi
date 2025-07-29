# 5. v3/scripts/docker-entrypoint.sh
#!/bin/bash
set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting October CMS v${OCTOBER_VERSION} container...${NC}"

# Fix permissions
echo "Setting permissions..."
chown -R october:october /var/www/html
chmod -R 755 /var/www/html

# Create required directories
mkdir -p /var/log/php /run/php
chown -R october:october /var/log/php

# Wait for database
if [ -n "$DB_HOST" ]; then
    echo "Waiting for database at $DB_HOST:$DB_PORT..."
    timeout=60
    counter=0
    
    until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
        counter=$((counter + 1))
        if [ $counter -gt $timeout ]; then
            echo -e "${YELLOW}Warning: Database connection timeout${NC}"
            break
        fi
        echo "Waiting for database... ($counter/$timeout)"
        sleep 1
    done
fi

# Check if October is installed
if [ ! -f "/var/www/html/artisan" ]; then
    echo -e "${YELLOW}October CMS is not installed.${NC}"
    echo "Run the install script or use: docker exec -it <container> install-october.sh"
fi

# Start the main process
echo -e "${GREEN}Starting supervisord...${NC}"
exec "$@"

---

# 6. v3/scripts/install-october.sh
#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}October CMS v${OCTOBER_VERSION} Installation Script${NC}"

cd /var/www/html

# Check if already installed
if [ -f "artisan" ]; then
    echo -e "${YELLOW}October CMS is already installed!${NC}"
    exit 0
fi

# Install October via Composer
echo "Installing October CMS v${OCTOBER_VERSION}..."
composer create-project october/october . "${OCTOBER_VERSION}.*" --prefer-dist --no-interaction

# Generate application key
echo "Generating application key..."
php artisan key:generate

# Run migrations
echo "Running migrations..."
php artisan october:migrate

# Set permissions
echo "Setting permissions..."
chown -R october:october /var/www/html
chmod -R 755 storage bootstrap/cache

echo -e "${GREEN}Installation complete!${NC}"
echo "Don't forget to create an admin user:"
echo "php artisan create:admin"
