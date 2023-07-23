FROM php:fpm-alpine
RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    freetype-dev \
    jpeg-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd