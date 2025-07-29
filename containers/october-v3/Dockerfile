FROM ubuntu:22.04

# Arguments
ARG OCTOBER_VERSION=3.7
ARG PHP_VERSION=8.1

# Labels
LABEL maintainer="framirez@healthytek.cl" \
      description="October CMS v${OCTOBER_VERSION}" \
      version="${OCTOBER_VERSION}" \
      php.version="${PHP_VERSION}" \
      laravel.version="10"

# Environment
ENV TZ=America/Santiago \
    DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=${PHP_VERSION} \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    OCTOBER_VERSION=${OCTOBER_VERSION}

# Install dependencies
RUN apt-get update && apt-get install -y \
    # System utilities
    curl wget git unzip vim ca-certificates tzdata \
    # PHP 8.1
    php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-json php${PHP_VERSION}-mysql php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-intl php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-redis php${PHP_VERSION}-imagick \
    # Process manager
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

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
COPY config/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini
COPY config/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy scripts
COPY scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Configure PHP for October CMS
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php/${PHP_VERSION}/fpm/php.ini

# Set permissions
RUN chown -R october:october /var/www/html \
    && chmod -R 755 /var/www/html

VOLUME ["/var/www/html"]
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD php-fpm${PHP_VERSION} -t || exit 1

ENV OCTOBER_CMS_VERSION=3.7 \
    LARAVEL_VERSION=10

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"] 