# shared/scripts/healthcheck-october.sh
#!/bin/bash

# Verificar que PHP-FPM esté corriendo
php-fpm -t || exit 1

# Verificar que October responda
if [ -f /var/www/html/artisan ]; then
    php /var/www/html/artisan up || exit 1
fi

# Verificar conectividad a base de datos
php -r "
try {
    \$pdo = new PDO(
        'pgsql:host=' . getenv('DB_HOST') . ';port=' . getenv('DB_PORT') . ';dbname=' . getenv('DB_DATABASE'),
        getenv('DB_USERNAME'),
        getenv('DB_PASSWORD')
    );
    echo 'Database: OK';
} catch (Exception \$e) {
    exit(1);
}
"