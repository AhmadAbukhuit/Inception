FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add --no-cache php-fpm php

RUN mkdir -p /usr/share/webapps/ && mkdir -p /usr/logs/php-fpm && cd /usr/share/webapps/

RUN wget https://wordpress.org/wordpress-7.0.4.tar.gz

RUN tar -xzvf wordpress-7.0.4.tar.gz && rm wordpress-7.0.4.tar.gz

WORKDIR /

COPY ./tools/main.sh  ./main.sh

ENTRYPOINT ["/main.sh"]
