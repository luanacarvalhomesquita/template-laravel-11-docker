FROM php:8.3.7-fpm-alpine3.20

WORKDIR /var/www

ENV TZ=Europe/Lisbon

RUN apk update
RUN apk add --no-cache libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev freetype freetype-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./ /var/www

# Giving permission to laravel logs
RUN chmod -R 777 /var/www/storage

# Instalar as dependências do Composer
RUN composer install

# Certifique-se de que o arquivo .env está presente
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Gere a chave da aplicação Laravel
RUN php artisan key:generate

# Supervidor config
RUN apk --no-cache add curl
RUN curl -o /usr/local/bin/supercronic -L https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64
RUN chmod +x /usr/local/bin/supercronic

RUN apk --no-cache add curl supervisor

COPY supervisord.conf /etc/supervisord.conf

# Add crontab file in the cron directory
COPY ./schedule/crontab /etc/cron.d/subscription-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/subscription-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log && chmod 0644 /var/log/cron.log

# Run the command on container startup
EXPOSE 9000

CMD supervisord -c /etc/supervisord.conf
