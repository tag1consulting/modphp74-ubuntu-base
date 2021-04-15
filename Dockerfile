FROM ubuntu:focal

LABEL name="php-base-ubuntu-modphp74" \
      maintainer="support@tag1consulting.com" \
      vendor="Tag1 Consulting" \
      version="1.0" \
      release="1" \
      summary="Simple base docker image for running PHP sites, Drupal oriented" 

ENV OPCACHE_MEMORY_CONSUMPTION 128
ENV HTTPD_MAX_REQUEST_WORKERS 150
ENV PHP_MEMORY_LIMIT 256M
ENV HTTPD_MAX_CONNECTIONS_PER_CHILD 2000

RUN apt-get update \
 && apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      tini \
      libapache2-mod-php7.4 \
      php7.4 \
      php7.4-cli \
      php7.4-curl \
      php7.4-gd \
      php7.4-json \
      php7.4-intl \
      php7.4-mbstring \
      php7.4-mysql \
      php7.4-pgsql \
      php7.4-opcache \
      php7.4-soap \
      php7.4-xml \
      php7.4-xmlrpc \
      php-igbinary \
      php-memcached \
      php-apcu \
      php-redis \
      php-zip \
      php-imagick \
 && rm -rf /var/lib/apt/lists/* \
 && a2enmod rewrite && a2enmod remoteip
      
# Log to stdout/stderr
RUN ln -sfT /dev/stdout /var/log/apache2/access.log && \
    ln -sfT /dev/stdout /var/log/apache2/other_vhosts_access.log && \
    ln -sfT /dev/stderr /var/log/apache2/error.log

# Make sure apache has permissions to write
RUN chown -R www-data:0 /var/log/apache2 /run/apache2 && \
    chmod -R g+w /var/log/apache2 /run/apache2


# Apache can't listen on 80 when not starting as root
RUN sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf

RUN { \
    echo '<IfModule mpm_prefork_module>'; \
    echo '  StartServers 5'; \
    echo '  MinSpareServers 5'; \
    echo '  MaxSpareServers 10'; \
    echo '  MaxRequestWorkers ${HTTPD_MAX_REQUEST_WORKERS}'; \
    echo '  MaxConnectionsPerChild ${HTTPD_MAX_CONNECTIONS_PER_CHILD}'; \
    echo '</IfModule>'; \
  } > /etc/apache2/mods-enabled/mpm_prefork.conf

#Read XFF headers, note this is insecure if you are not sanitizing
#XFF in front of the container
RUN { \
    echo '<IfModule mod_remoteip.c>'; \
    echo '  RemoteIPHeader X-Forwarded-For'; \
    echo '</IfModule>'; \
  } > /etc/apache2/mods-enabled/remoteip.conf

#Correctly set SSL if we are terminated by it
RUN { \
    echo 'SetEnvIf X-Forwarded-Proto "https" HTTPS=on'; \
  } > /etc/apache2/conf-enabled/remote_ssl.conf

# Set recommended opcache settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}'; \
		echo 'opcache.interned_strings_buffer=16'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /etc/php/7.4/apache2/conf.d/opcache-recommended.ini

RUN { \
		echo 'expose_php=Off'; \
		echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
	} > /etc/php/7.4/apache2/conf.d/php-defaults.ini

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

WORKDIR /app

USER www-data

ENTRYPOINT [ "tini", "--", "/usr/local/bin/entrypoint.sh" ]
