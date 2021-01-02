FROM mautic/mautic:v3

LABEL vendor="Mautic"
LABEL maintainer="Danilo Cruz <danilo@plimtelecom.com.br>"

RUN mkdir -p /var/lib/mysql
VOLUME /var/lib/mysql

ENV MAUTIC_VERSION 3.2.2
ENV MAUTIC_SHA1 225dec8fbac05dfb77fdd7ed292a444797db215f

ENV APACHE_SSL false
ENV APACHE_SSL_CRT cert.crt
ENV APACHE_SSL_KEY cert.key
ENV APACHE_FORCE_HTTPS false

ENV MAUTIC_DB_USE_LOCAL true
ENV MAUTIC_DB_BIND 127.0.0.1
ENV MAUTIC_DB_HOST 127.0.0.1
ENV MAUTIC_DB_USER mautic
ENV MAUTIC_DB_PASSWORD mautic
ENV MAUTIC_DB_NAME mautic
ENV MAUTIC_DB_ROOT_PASSWORD mautic

RUN apt -y update
RUN apt install -y --no-install-recommends mariadb-server mariadb-client
RUN update-rc.d mysql disable
RUN sed -i '/^bind-address/a\skip-host-cache' /etc/mysql/mariadb.conf.d/50-server.cnf
RUN sed -i '/^bind-address/a\skip-name-resolve' /etc/mysql/mariadb.conf.d/50-server.cnf
RUN sed -i '/^bind-address/a\innodb_strict_mode\t= 0' /etc/mysql/mariadb.conf.d/50-server.cnf
RUN sed -i '/^bind-address/a\innodb_log_file_size\t= 512M' /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 80
EXPOSE 443
EXPOSE 3306

RUN sed -i '/^[[:blank:]]*#/d;s/#.*//' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i 's/certs\/ssl-cert-snakeoil.pem/private\/cert.crt/g' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i 's/ssl-cert-snakeoil.key/cert.key/g' /etc/apache2/sites-available/default-ssl.conf


# Download package and extract to web volume
RUN curl -o mautic.zip -SL https://github.com/mautic/mautic/releases/download/${MAUTIC_VERSION}/${MAUTIC_VERSION}.zip \
    ; echo "$MAUTIC_SHA1 *mautic.zip" | sha1sum -c - \
    ; mkdir /usr/src/mautic \
    ; unzip mautic.zip -d /usr/src/mautic \
    ; rm mautic.zip \
    ; sed -i 's/\$model->hitPage(\$entity, \$this->request, 404)/#&/' /usr/src/mautic/app/bundles/PageBundle/Controller/PublicController.php \
    ; chown -R www-data:www-data /usr/src/mautic \
    ; find /var/www/ -type d -not -perm 755 -exec chmod 755 {} + \
    ; find /var/www/ -type f -not -perm 644 -exec chmod 644 {} +

ADD ./entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]