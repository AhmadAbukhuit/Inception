set -e 

if [[ ! -d "$DATADIR/mysql" ]]; then
	mariadb-install-db --user=mysql \ 
		--datadir=/var/lib/mysql \
		--skip-test-db
fi

mariadbd \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --skip-networking


exec mariadbd


