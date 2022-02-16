FROM php:8.1-apache

# set up php.ini
RUN cp -p /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
  && sed -ri -e 's!^;date.timezone =!date.timezone = Asia/Tokyo!' /usr/local/etc/php/php.ini \
  && sed -ri -e 's!^;mbstring.language = Japanese!mbstring.language = Japanese!' /usr/local/etc/php/php.ini \
  && sed -ri -e 's!^;mbstring.detect_order = auto!mbstring.detect_order = ASCII,ISO-2022-JP,UTF-8,eucJP-win,SJIS-win!' /usr/local/etc/php/php.ini \
  && sed -ri -e 's!^;mbstring.substitute_character = none!mbstring.substitute_character = none!' /usr/local/etc/php/php.ini \
  && sed -i -e '$ a mbstring.func_overload = 0\n' /usr/local/etc/php/php.ini

# install packages
RUN apt-get update && \
    apt-get -y install \
      curl \
      wget \
      vim \
      git \
      libzip-dev \ 
      unzip \ 
      zlib1g-dev \
      less \
      libpq-dev \
      libonig-dev \
      postgresql \
      nodejs \
      npm

# set up apache's conf files
RUN a2enmod headers
RUN sed -ri -e 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf && \
    sed -ri -e 's/^#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf-available/security.conf && \
    sed -ri -e 's/^ServerSignature On/#ServerSignature On/' /etc/apache2/conf-available/security.conf && \
    sed -ri -e 's/^#Header set X-Frame-Options:/Header set X-Frame-Options:/' /etc/apache2/conf-available/security.conf && \
    sed -ri -e 's/^#Header set X-Content-Type-Options:/Header set X-Content-Type-Options:/' /etc/apache2/conf-available/security.conf && \
    { \
        echo 'FileETag None'; \
        echo 'Header unset "X-Powered-By"'; \
        echo 'RequestHeader unset Proxy'; \
        echo 'Header set X-XSS-Protection "1; mode=block"'; \
        echo '<Directory /var/www/html>'; \
        echo ' AllowOverride All'; \
        echo ' Options -Indexes'; \
        echo '</Directory>'; \
    } >> /etc/apache2/conf-available/security.conf

# enable mod-rewrite
RUN a2enmod rewrite

# change the document-root directory for Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/bootcamp/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# set up composer
COPY --from=composer /usr/bin/composer /usr/bin/composer　
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
ENV PATH $PATH:/composer/vendor/bin

# set up Laravel
WORKDIR /var/www/html
RUN composer global require "laravel/installer" && \
    laravel new bootcamp && \
    chown -R www-data:www-data /var/www/html/bootcamp/storage && \
    chown -R www-data:www-data /var/www/html/bootcamp/bootstrap/cache

# Cleaning
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# open ports to connect with the host
EXPOSE 80

