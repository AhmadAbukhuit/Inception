FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add --no-cache php-fpm php php84-mysqli php84-phar php84-zip php84-mbstring

RUN mkdir -p /usr/logs/php-fpm /usr/src/wordpress

RUN wget -O /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x /tmp/wp-cli.phar && mv /tmp/wp-cli.phar /usr/local/bin/wp

WORKDIR /

RUN php -d memory_limit=256M /usr/local/bin/wp core download --path=/usr/src/wordpress

COPY ./tools/main.sh  ./main.sh

COPY ./conf/www.conf /etc/php84/php-fpm.d/www.conf

ENTRYPOINT ["/main.sh"]
