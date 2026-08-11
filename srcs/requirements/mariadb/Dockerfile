FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add mariadb mariadb-client

WORKDIR /

RUN chown mysql:mysql /var/lib/mysql

COPY ./tools/main.sh ./main.sh

ENTRYPOINT ["/main.sh"]
