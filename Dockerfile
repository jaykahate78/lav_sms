FROM php:8.2-apache-bookworm
ENV COMPOSER_ALLOW_SUPERUSER=1
# Laravel 8.42 uses legacy interfaces that trigger PHP 8.2 deprecation notices.
# Suppress deprecations for this isolated synthetic-data demo only.
RUN printf '%s\n' 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED' > /usr/local/etc/php/conf.d/legacy-demo.ini
RUN apt-get update && apt-get install -y --no-install-recommends git unzip curl libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libicu-dev libpq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j2 pdo_mysql mysqli pdo_pgsql pgsql gd zip intl bcmath \
    && a2enmod rewrite headers \
    && sed -i 's/Listen 80/Listen 10000/' /etc/apache2/ports.conf \
    && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY ./docker/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
WORKDIR /var/www/html
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts --optimize-autoloader
COPY . .
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod +x docker/entrypoint.sh \
    && printf 'ok\n' > public/healthz
EXPOSE 10000
CMD ["/var/www/html/docker/entrypoint.sh"]
