FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl

RUN docker-php-ext-install mysqli

RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

COPY app /var/www/html

WORKDIR /var/www/html

RUN composer require aws/aws-sdk-php
