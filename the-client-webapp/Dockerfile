FROM php:7.3-apache
RUN docker-php-ext-install mysqli
WORKDIR /app
COPY . /app
COPY ./www /var/www/html
