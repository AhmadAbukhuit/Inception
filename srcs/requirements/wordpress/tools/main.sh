#!/bin/sh
set -eu

WP_PASS="$(cat /run/secrets/db_password)"
WP_ADMIN_PASS="$(cat /run/secrets/db_root_password)"
export WP_PASS WP_ADMIN_PASS

exec php-fpm84 -F
