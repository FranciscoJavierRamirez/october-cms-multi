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

# Laravel 12 specific optimizations
echo "Applying Laravel 12 optimizations..."
php artisan config:cache || true
php artisan route:cache || true

echo -e "${GREEN}Installation complete!${NC}"
echo "Don't forget to create an admin user:"
echo "php artisan create:admin"