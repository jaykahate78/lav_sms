FROM php:8.0-apache-bullseye
ENV COMPOSER_ALLOW_SUPERUSER=1
# PHP 8.0 is an EOL compatibility runtime for isolated demo use only.
# Upgrade Laravel and PHP before any production rollout.
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g; s|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list \
    && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99archive
RUN apt-get update -o Acquire::Check-Valid-Until=false && apt-get install -y --no-install-recommends git unzip curl libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libicu-dev libpq-dev \
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
