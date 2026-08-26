#!/bin/sh
set -eu

WP_PASS="$(cat /run/secrets/db_password)"
export WP_PASS

chown -R nobody:nobody /usr/src/wordpress

exec php-fpm84 -F
