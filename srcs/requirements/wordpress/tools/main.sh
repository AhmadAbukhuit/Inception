#!/bin/sh
set -eu

WP_PASS="$(cat /run/secrets/db_password)"
WP_ROOT_PASS="$(cat /run/secrets/db_root_password)"
export WP_PASS WP_ROOT_PASS

chown -R nobody:nobody /usr/src/wordpress
if [ ! -f /usr/src/wordpress/wp-config.php ]; then
  wp config create --dbname=${DB_NAME} --dbuser=${WP_USER} --dbpass=${WP_PASS} --dbhost=mariadb --path=/usr/src/wordpress
fi
if ! wp core is-installed --path=/usr/src/wordpress; then
  wp core install --url="https://${HOST}" --title="akamamji" --admin_user=${WP_ADMIN} --admin_password=${WP_ROOT_PASS} \
    --admin_email=${WP_ADMIN}@${HOST} --path=/usr/src/wordpress
fi
if ! wp user get "$WP_USER" --path=/usr/src/wordpress >/dev/null 2>&1; then
  wp user create ${WP_USER} ${WP_USER}@${HOST} --role=contributor --user_pass=${WP_PASS} --path=/usr/src/wordpress
fi

exec php-fpm84 -F
