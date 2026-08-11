#!/bin/sh
set -eu 

if [ ! -d "$DATADIR/mysql" ]; then
	echo "setup the mariadb data directory"
	mariadb-install-db --user=mysql \
		--datadir="$DATADIR" \
		--skip-test-db

	echo "running the mariadbd...."
	mariadbd \
	--user=mysql \
	--datadir="$DATADIR" \
	--bootstrap <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

CREATE USER IF NOT EXISTS '${DB_USER}'@'%'
    IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES
    ON ${DB_NAME}.*
    TO '${DB_USER}'@'%';
EOF
fi

exec mariadbd \
    --user=mysql \
    --datadir="$DATADIR" \
    --bind-address=0.0.0.0 \
    --port=3306
