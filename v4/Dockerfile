# v4/Dockerfile  
# October CMS v4.0 - Container minimalista (sin Vue.js, sin Tailwind automático)

FROM ubuntu:22.04

# Arguments
ARG OCTOBER_VERSION=4.0
ARG PHP_VERSION=8.2

# Labels
LABEL maintainer="framirez@healthytek.cl" \
      description="October CMS v${OCTOBER_VERSION} - Minimalista" \
      version="${OCTOBER_VERSION}" \
      php.version="${PHP_VERSION}" \
      laravel.version="12" \
      frontend="manual"

# Environment variables
ENV TZ=America/Santiago \
    DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=${PHP_VERSION} \
    NODE_VERSION=20 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    OCTOBER_VERSION=${OCTOBER_VERSION}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # System utilities básicas
    curl \
    wget \
    git \
    unzip \
    vim \
    ca-certificates \
    # PHP 8.2 y extensiones mínimas requeridas para Laravel 12
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-imagick \
    # Laravel 12 + October v4 specific requirements
    php${PHP_VERSION}-pcntl \
    php${PHP_VERSION}-posix \
    php${PHP_VERSION}-sockets \
    php${PHP_VERSION}-tokenizer \
    php${PHP_VERSION}-fileinfo \
    php${PHP_VERSION}-iconv \
    # Supervisor para gestión de procesos
    supervisor \
    # Herramientas de sistema
    tzdata \
    # Node.js (disponible si quieres usar Tailwind manualmente)
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    # Limpiar cache
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Configure timezone
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

# Create application user
RUN groupadd -g 1000 october \
    && useradd -u 1000 -g october -m -d /home/october -s /bin/bash october

# Create directory structure
RUN mkdir -p \
    /var/www/html \
    /var/log/php \
    /var/log/supervisor \
    /run/php \
    /home/october/.composer \
    && chown -R october:october /var/www/html /home/october \
    && chmod -R 755 /var/www/html

# PHP configuration for October v4.0 + Laravel 12
COPY config/php/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini
COPY config/php/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY config/php/opcache.ini /etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini

# Supervisor configuration
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Scripts
COPY scripts/docker-entrypoint.sh /usr/local/bin/
COPY scripts/install-october.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/install-october.sh

# Configure PHP settings for October CMS v4.0
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    # Laravel 12 + October v4 optimizations
    && echo "opcache.jit=1255" >> /etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini \
    && echo "opcache.jit_buffer_size=256M" >> /etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini

# Set proper permissions
RUN chown -R october:october /var/www/html \
    && chmod -R 755 /var/www/html

# Volumes
VOLUME ["/var/www/html"]

# Expose only PHP-FPM port (NGINX is shared)
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD php-fpm${PHP_VERSION} -t || exit 1

# Environment variables for October v4.0
ENV OCTOBER_CMS_VERSION=4.0 \
    LARAVEL_VERSION=12 \
    NEW_DASHBOARD_ENABLED=true \
    BUILDER_PLUGIN_VERSION=4.x \
    OCTOBER_NATIVE_FEATURES=true

# Entry point
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
