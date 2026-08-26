FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add --no-cache php-fpm php php84-mysqli

RUN mkdir -p /usr/logs/php-fpm /usr/src/wordpress

RUN wget -O /tmp/wordpress.tar.gz https://wordpress.org/wordpress-7.0.4.tar.gz \
&& tar -xzf /tmp/wordpress.tar.gz -C /usr/src/wordpress \
--strip-components=1 && rm /tmp/wordpress.tar.gz

WORKDIR /

COPY ./tools/main.sh  ./main.sh

COPY ./conf/www.conf /etc/php84/php-fpm.d/www.conf

ENTRYPOINT ["/main.sh"]
