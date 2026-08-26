#!/bin/sh
set -eu

openssl req \
  -x509 \
  -newkey rsa:2048 \
  -noenc \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -days 365 \
  -subj "/C=JO/ST=Amman/L=Amman/O=Inception/CN=akamamji.42.fr" \
  -addext "subjectAltName=DNS:akamamji.42.fr,DNS:localhost,IP:127.0.0.1"

exec nginx -g 'daemon off;'
