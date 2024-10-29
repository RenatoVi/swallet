FROM php:8.3-fpm-alpine

# Args
ARG SSH_PRIVATE_KEY

WORKDIR /var/www/html/project

# Install NGINX
RUN apk update \
    && apk upgrade \
    && apk add nginx supervisor

COPY ./docker/nginx/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /usr/share/nginx/www
RUN mkdir -p /run/nginx \
    && mkdir -p /tmp/logDir/

# Install supervisord
COPY ./docker/supervisord/DEV-supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Config php-fpm
COPY ./docker/php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf

# Install dependencies
RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
  libxml2-dev curl-dev linux-headers oniguruma-dev imap-dev openssl-dev git openssh-client

# Install extensions
RUN docker-php-ext-install dom curl mbstring imap opcache

# Install redis php and enable
RUN pecl install redis \
  && docker-php-ext-enable redis

RUN docker-php-ext-install pcntl

# Composer
RUN \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && HASH="$(wget -q -O - https://composer.github.io/installer.sig)" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug
ADD ./docker/php/20-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "include_path=/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" >> /usr/local/etc/php/php.ini

# Copy files
COPY . /var/www/html/project

# Setup cron
#RUN touch /var/log/cron.log
#RUN echo "* * * * * php /var/www/html/project/artisan schedule:run >> /var/log/cron.log 2>&1" >> /var/spool/cron/crontabs/root

# Setting permissions
RUN \
    chown -R www-data:www-data /var/lib/nginx && \
    chown -R www-data:www-data /var/www/html/project && \
    chown -R www-data:www-data /tmp/logDir && \
    find /var/www/html/project -type f -exec chmod 644 {} \; && \
    find /var/www/html/project -type d -exec chmod 755 {} \;

# UUID
COPY ./docker/uuid/uuid.sh /usr/local/bin
RUN chown root:root /usr/local/bin/uuid.sh && chmod +x /usr/local/bin/uuid.sh

COPY ./docker/php/php.ini /usr/local/etc/php/php.ini

EXPOSE 80 443

# Remove Build Dependencies
RUN apk del -f $PHPIZE_DEPS libxml2-dev curl-dev linux-headers oniguruma-dev imap-dev openssl-dev

# Executing UUID command generator
ENTRYPOINT ["/usr/local/bin/uuid.sh"]

CMD sh -c "composer install && /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf"
