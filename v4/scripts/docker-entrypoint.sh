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
    echo -e "${YELLOW}October CMS v${OCTOBER_VERSION} is not installed.${NC}"
    echo "Run the install script or use: docker exec -it <container> install-october.sh"
fi

# Start the main process
echo -e "${GREEN}Starting supervisord...${NC}"
exec "$@"