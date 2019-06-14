FROM php:7.2
MAINTAINER Sergiu Cazac <kilobyte2007@gmail.com>

#
# Install basic requirements
#
RUN apt-get update \
 && apt-get install -y \
 curl \
 apt-transport-https \
 git \
 build-essential \
 libssl-dev \
 wget \
 unzip \
 bzip2 \
 libbz2-dev \
 zlib1g-dev \
 mysql-client \
 libfontconfig \
 libfreetype6-dev \
 libjpeg62-turbo-dev \
 libpng-dev \
 libicu-dev \
 libxml2-dev \
 libldap2-dev \
 libmcrypt-dev \
 fabric \
 jq \
 gnupg \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#
# Install Node (with NPM)
#
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update \
 && apt-get install -y \
 nodejs

#
# Install Composer and Drush
#
ENV PATH "/composer/vendor/bin:$PATH"
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
ENV COMPOSER_VERSION 1.8.6

RUN curl -s -f -L -o /tmp/installer.php https://raw.githubusercontent.com/composer/getcomposer.org/da290238de6d63faace0343efbdd5aa9354332c5/web/installer \
 && php -r " \
    \$signature = '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
 && rm /tmp/installer.php \
 && composer --ansi --version --no-interaction

#
# Install additional php extensions
#
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) \
      bcmath \
      bz2 \
      calendar \
      exif \
      ftp \
      gd \
      gettext \
      intl \
      ldap \
      mcrypt \
      mysqli \
      opcache \
      pcntl \
      pdo_mysql \
      shmop \
      soap \
      sockets \
      sysvmsg \
      sysvsem \
      sysvshm \
      zip \
    && pecl install redis apcu \
    && docker-php-ext-enable redis apcu


#
# PHP configuration
#
# Set timezone
RUN echo "date.timezone = \"Europe/Helsinki\"" > $PHP_INI_DIR/conf.d/timezone.ini
# Increase PHP memory limit
RUN echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/timezone.ini
# Set upload limit
RUN echo "upload_max_filesize = 128M\npost_max_size = 128M" > $PHP_INI_DIR/conf.d/00-max_filesize.ini
