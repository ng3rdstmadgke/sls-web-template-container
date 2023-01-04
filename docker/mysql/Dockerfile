FROM mysql:8

COPY ./docker/mysql/check-mysql-boot.sh /usr/local/bin/check-mysql-boot.sh
RUN chmod 755 /usr/local/bin/check-mysql-boot.sh
COPY ./docker/mysql/config/conf.d/custom.cnf /etc/mysql/conf.d/