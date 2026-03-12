# Use official PHP + Apache image
FROM php:8.2-apache

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    && docker-php-ext-install mysqli

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Copy app code into Apache root
COPY app/ /var/www/html/

# Set working directory
WORKDIR /var/www/html

# Install AWS SDK for PHP (for Secrets Manager access)
RUN composer require aws/aws-sdk-php

# Expose port 80
EXPOSE 80