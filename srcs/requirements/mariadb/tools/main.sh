#!/bin/sh
set -eu

mkdir -p "$(dirname "$SOCKET")"
chown mysql:mysql "$(dirname "$SOCKET")"

WP_PASS="$(cat /run/secrets/db_password)"
WP_ADMIN_PASS="$(cat /run/secrets/db_root_password)"
export WP_PASS WP_ADMIN_PASS

if [ ! -d "$DATADIR/mysql" ]; then
  echo "setting up MariaDB data directory"

  mariadb-install-db \
    --user=mysql \
    --datadir="$DATADIR" \
    --skip-test-db

  echo "starting temporary MariaDB server"

  mariadbd \
    --user=mysql \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --skip-networking &

  pid=$!

  ready=0

  for i in $(seq 0 6); do
    if mariadb-admin \
      --protocol=socket \
      --socket="$SOCKET" \
      ping >/dev/null 2>&1; then
      ready=1
      break
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
      echo "temporary MariaDB server exited unexpectedly" >&2
      wait "$pid" || true
      exit 1
    fi

    sleep 5
  done

  if [ "$ready" -ne 1 ]; then
    echo "MariaDB failed to become ready" >&2
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    exit 1
  fi

  echo "bootstrapping database"

  envsubst <bootstrap.sql >/tmp/bootstrap.sql

  mariadb \
    --protocol=socket \
    --socket="$SOCKET" \
    -u root </tmp/bootstrap.sql

  rm -f /tmp/bootstrap.sql

  mariadb-admin \
    --protocol=socket \
    --socket="$SOCKET" \
    -u root shutdown

  wait "$pid"
fi

echo "starting MariaDB"

exec mariadbd \
  --user=mysql \
  --datadir="$DATADIR" \
  --port=3306
