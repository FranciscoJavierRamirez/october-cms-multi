
FROM php:8.2-fpm

# Arguments
ARG OCTOBER_VERSION=4.0
ARG PHP_VERSION=8.2

# Labels
LABEL maintainer="framirez@healthytek.cl" \
      description="October CMS v${OCTOBER_VERSION}" \
      version="${OCTOBER_VERSION}" \
      php.version="${PHP_VERSION}" \
      laravel.version="12"

# Environment
ENV TZ=America/Santiago \
    DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=${PHP_VERSION} \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    OCTOBER_VERSION=${OCTOBER_VERSION}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl wget git unzip vim ca-certificates tzdata \
    supervisor \
    # PostgreSQL dependencies
    libpq-dev \
    # GD dependencies
    libpng-dev libjpeg-dev libfreetype6-dev \
    # Intl dependencies
    libicu-dev \
    # Zip dependencies
    libzip-dev \
    # MBString dependencies
    libonig-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install PHP extensions for October v4.0 (sin SQLite3)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    pdo pdo_mysql pdo_pgsql \
    bcmath gd intl mbstring opcache zip

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Configure timezone
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create user
RUN groupadd -g 1000 october \
    && useradd -u 1000 -g october -m -d /home/october -s /bin/bash october

# Create directories
RUN mkdir -p /var/www/html /var/log/php /run/php \
    && chown -R october:october /var/www/html /var/log/php

# Copy configurations
COPY config/php.ini /usr/local/etc/php/php.ini
COPY config/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy scripts
COPY scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Configure PHP for October v4.0
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /usr/local/etc/php/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 100M/' /usr/local/etc/php/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/' /usr/local/etc/php/php.ini \
    && sed -i 's/memory_limit = 128M/memory_limit = 512M/' /usr/local/etc/php/php.ini

# Laravel 12 + October v4 optimizations
RUN echo "opcache.jit=1255" >> /usr/local/etc/php/conf.d/10-opcache.ini \
    && echo "opcache.jit_buffer_size=256M" >> /usr/local/etc/php/conf.d/10-opcache.ini

# Set permissions
RUN chown -R october:october /var/www/html \
    && chmod -R 755 /var/www/html

VOLUME ["/var/www/html"]
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD php-fpm -t || exit 1

ENV OCTOBER_CMS_VERSION=4.0 \
    LARAVEL_VERSION=12 \
    NEW_DASHBOARD_ENABLED=true

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
