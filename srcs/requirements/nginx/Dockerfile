FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add --no-cache nginx openssl

RUN mkdir -p /usr/www /etc/nginx/ssl && chown -R nginx:www-data /usr/www /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

WORKDIR /

COPY ./tools/main.sh ./main.sh

ENTRYPOINT ["/main.sh"]
