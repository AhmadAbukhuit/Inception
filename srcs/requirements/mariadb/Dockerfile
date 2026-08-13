FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add --no-cache mariadb mariadb-client gettext

WORKDIR /

RUN chown mysql:mysql /var/lib/mysql

COPY ./conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY ./tools/main.sh ./main.sh
COPY ./conf/bootstrap.sql ./bootstrap.sql

ENTRYPOINT ["/main.sh"]
