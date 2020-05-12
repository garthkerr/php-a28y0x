FROM php:7.4.5-fpm

ENV VERSION_MEMCACHED="3.1.4"
ENV VERSION_MCRYPT="1.0.3"
ENV VERSION_NEW_RELIC="newrelic-php5-9.10.1.263"

RUN set -x && DEBIAN_FRONTEND=noninteractive && \
  # newrelic agent
  curl -fsSL https://download.newrelic.com/php_agent/release/${VERSION_NEW_RELIC}-linux.tar.gz | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* && \
  sed -i \
      -e "s/newrelic.appname =.*/newrelic.appname = \${NEW_RELIC_APP_NAME}/" \
      -e "s/newrelic.license =.*/newrelic.license = \${NEW_RELIC_LICENSE_KEY}/" \
      /usr/local/etc/php/conf.d/newrelic.ini && \
  # build tools
  apt-get update && \
  apt-get install -y autoconf gcc make pkg-config && \
  apt-get install -y libc-dev libfreetype6-dev libicu-dev libjpeg62-turbo-dev libonig-dev && \
  # extensions
  docker-php-ext-install bcmath intl opcache mbstring && \
  # extension gd
  docker-php-ext-configure gd && \
  docker-php-ext-install -j$(nproc) gd && \
  # backport memcached
  apt-get install -y libmemcached-dev zlib1g-dev && \
  pecl -q install memcached-${VERSION_MEMCACHED} && \
  docker-php-ext-enable memcached && \
  # backport mcrypt
  apt-get install -y libmcrypt-dev && \
  pecl -q install mcrypt-${VERSION_MCRYPT} && \
  docker-php-ext-enable mcrypt && \
  # server dependencies
  apt-get install -y nginx nscd && \
  apt-get clean && \
  # configure php-fpm
  rm -rf /usr/local/etc/php-fpm.d/*

EXPOSE 80

CMD service nginx start && service nscd start && php-fpm
