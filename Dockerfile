# Contexto de construcción: la raíz de https://github.com/memouk/moodle
FROM php:8.3-apache-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libicu-dev \
        libzip-dev \
        libxml2-dev \
        unzip \
        curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd intl zip soap exif mysqli pdo_mysql opcache \
    && docker-php-ext-enable sodium \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . /var/www/html

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --no-interaction --prefer-dist --ignore-platform-reqs \
    && mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/html /var/www/moodledata \
    && sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/*.conf \
    && printf '%s\n' \
        '<Directory /var/www/html/public>' \
        '    AllowOverride All' \
        '    Require all granted' \
        '    DirectoryIndex index.php' \
        '    FallbackResource /r.php' \
        '</Directory>' \
        > /etc/apache2/conf-available/moodle.conf \
    && a2enconf moodle \
    && printf '%s\n' '<?php http_response_code(200); echo "ok";' > /var/www/html/public/healthz.php

COPY docker/php.ini /usr/local/etc/php/conf.d/moodle.ini
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
