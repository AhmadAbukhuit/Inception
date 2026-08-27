# Inception Administration and Developer Guide

This guide explains how to configure, build, administer, and troubleshoot the activity from a fresh checkout. Routine users can follow [USER_DOC.md](USER_DOC.md).

## Prerequisites

Prepare a Linux virtual machine with:

- Docker Engine running.
- Docker Compose v2, invoked as `docker compose`.
- GNU Make.
- Internet access during the first build for the Alpine base layers, packages, and WP-CLI/WordPress downloads.
- Permission to use the Docker daemon, edit the host's hostname mapping, and create `/home/akamamji/data`.
- TCP port `443` available.

Verify the tools:

```sh
docker --version
docker compose version
make --version
docker info
```

## Repository layout

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    ├── secrets
    │   ├── db_password.txt
    │   └── db_root_password.txt
    └── requirements
        ├── mariadb
        ├── nginx
        └── wordpress
```

Each service directory contains its Dockerfile and the configuration or entrypoint files needed to build that service locally.

## Configure a fresh checkout

### 1. Set the project identity

The current sources are configured for the 42 login `akamamji` and domain `akamamji.42.fr`. If this identity changes, update all of these together before building:

- `HOST` in `srcs/.env`.
- `server_name` in `srcs/requirements/nginx/conf/nginx.conf`.
- Certificate common name and subject alternative names in `srcs/requirements/nginx/tools/main.sh`.
- Both host `device` paths in `srcs/docker-compose.yml`.
- The WordPress title in `srcs/requirements/wordpress/tools/main.sh`, if desired.

Keep the domain in the required `<login>.42.fr` form and keep the host data below `/home/<login>/data`.

### 2. Create the host data directories

For the current configuration:

```sh
sudo mkdir -p /home/akamamji/data/wordpress /home/akamamji/data/mysql
```

The Docker daemon and container entrypoints initialize ownership inside these directories. Do not pre-populate the MariaDB directory with unrelated files.

### 3. Create `srcs/.env`

Create the ignored `srcs/.env` file with these required keys:

```dotenv
HOST=akamamji.42.fr
DATADIR=/var/lib/mysql
DB_NAME=wordpress
WP_USER=<database-and-contributor-username>
WP_ADMIN=<wordpress-administrator-username>
SOCKET=/run/mysqld/mysql.sock
```

Rules and meanings:

| Variable | Purpose |
| --- | --- |
| `HOST` | Public WordPress hostname and URL. |
| `DATADIR` | MariaDB data directory inside its container. Keep `/var/lib/mysql` unless the mounts and image are changed too. |
| `DB_NAME` | Database created for WordPress. |
| `WP_USER` | MariaDB application username and initial WordPress contributor username. |
| `WP_ADMIN` | Initial WordPress administrator username. It must not contain `admin` or `administrator`, in any letter case. |
| `SOCKET` | Socket used while MariaDB performs its first-run bootstrap. |

Passwords do not belong in `.env`. The current runtime reads passwords only from Compose secrets; any password-like entries in a copied template should be removed.

### 4. Create the secrets

Create the directory and restrict it:

```sh
mkdir -p srcs/secrets
chmod 700 srcs/secrets
```

Using a local editor that does not record values in shell history, create two one-line files with strong, distinct passwords:

| File | Used for |
| --- | --- |
| `srcs/secrets/db_password.txt` | MariaDB `WP_USER` account and the initial WordPress contributor account. |
| `srcs/secrets/db_root_password.txt` | Initial WordPress `WP_ADMIN` account. The filename is legacy; the current MariaDB bootstrap does not assign it to the database root account. |

Then restrict access:

```sh
chmod 600 srcs/.env srcs/secrets/db_password.txt srcs/secrets/db_root_password.txt
```

Both `.env` and directories named `secrets` are covered by the repository's `.gitignore`. Confirm that credentials are not staged before every commit.

### 5. Configure hostname resolution

If the browser runs in the same VM, add:

```text
127.0.0.1 akamamji.42.fr
```

to `/etc/hosts`. If the browser runs on the host or another machine, map `akamamji.42.fr` to the VM's reachable IP instead and ensure the VM networking/firewall allows TCP `443`.

### 6. Validate the configuration

From the repository root:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config --quiet
```

No output and exit status `0` means the Compose file resolved successfully. This validates syntax and interpolation, not service startup.

## Build and launch

The Makefile entry point is:

```sh
make run
```

Compose builds missing local images and launches the stack in detached mode. To force a build after changing a Dockerfile, package, configuration file, or copied script, run:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build
make run
```

To rebuild without using cached layers:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build --no-cache
make run
```

Startup is health-gated: MariaDB initializes first, WordPress waits for MariaDB to become healthy, and NGINX waits for WordPress. On the first run, the entrypoints create the database, `wp-config.php`, the WordPress site, and two WordPress users.

## Makefile targets

| Target | Effect |
| --- | --- |
| `make run` | Run `docker compose up -d` with this project's Compose and environment files. |
| `make stop` | Run `docker compose down`; containers and the Compose network are removed, while persistent data is retained. |
| `make fclean` | Kill the three named containers, then prune unused Docker images, volumes, and networks across the Docker host. This has system-wide impact. |

Use `make fclean` only after inspecting all Docker resources on the VM. It is broader than this Compose project and is not required for a normal rebuild or restart.

## Container administration

Use a consistent Compose prefix from the repository root:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs -f
docker compose -f srcs/docker-compose.yml --env-file srcs/.env restart wordpress
docker compose -f srcs/docker-compose.yml --env-file srcs/.env stop nginx
docker compose -f srcs/docker-compose.yml --env-file srcs/.env start nginx
```

Inspect a single service:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=100 mariadb
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec wordpress sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec nginx nginx -t
```

Useful application checks:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec wordpress wp core is-installed --path=/usr/src/wordpress --allow-root
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec wordpress wp user list --path=/usr/src/wordpress --allow-root
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec mariadb mariadb-admin ping --host=127.0.0.1 --user=healthcheck --silent
```

## Persistence and volumes

The two Compose named volumes are:

| Logical volume | Container path | Host backing directory | Contents |
| --- | --- | --- | --- |
| `wordpress-vol` | `/usr/src/wordpress` | `/home/akamamji/data/wordpress` | WordPress core, plugins, themes, uploads, and `wp-config.php`. |
| `mariadb-vol` | `/var/lib/mysql` | `/home/akamamji/data/mysql` | MariaDB system tables and the WordPress database. |

List and inspect the Docker volume objects:

```sh
docker volume ls
docker volume inspect <compose-project>_wordpress-vol
docker volume inspect <compose-project>_mariadb-vol
```

The Compose project prefix is normally derived from the directory containing the Compose file; use `docker volume ls` to get the exact names.

`make stop`, container recreation, and image rebuilding do not erase the data. The initialization scripts deliberately skip bootstrap when they detect existing MariaDB or WordPress state. Consequently:

- Changing `.env` or secret files does not rename or update already-created accounts.
- Changing `DB_NAME`, `WP_USER`, or passwords on an existing installation can make WordPress unable to connect.
- Test bootstrap changes against empty, disposable data rather than production data.

Before destructive maintenance, back up both the database and WordPress files. A logical database backup can be created while the stack is running:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec -T mariadb mariadb-dump --user=root --all-databases > mariadb-backup.sql
sudo tar -C /home/akamamji/data -czf wordpress-files-backup.tar.gz wordpress
```

Store backups outside `/home/akamamji/data` and protect them as credentials may be present in `wp-config.php` and the database.

## Credential lifecycle

The two secret files are consumed during first-time initialization. They are also used whenever WordPress must create a missing configuration or user, but they do not overwrite existing account passwords.

For an existing site:

- Change WordPress account passwords through `/wp-admin/` or an appropriately secured WP-CLI session.
- Coordinate a MariaDB application-password rotation with the matching password in `/usr/src/wordpress/wp-config.php`.
- Do not pass passwords directly as command-line arguments, where they may be stored in shell history or visible to other processes.
- Back up the database first and verify WordPress connectivity before ending the maintenance window.

For a disposable clean installation, stop the stack, deliberately remove its persisted data, update the secrets, and launch again. Removing persistent data is irreversible unless a backup exists; verify the exact target directories and volumes before doing so.

## Networking and TLS

The custom bridge network provides DNS by service name:

- NGINX sends FastCGI requests to `wordpress:9000`.
- WordPress connects to `mariadb:3306`.
- Only `443:443` is published to the host.

NGINX enables only TLS 1.2 and TLS 1.3. Its entrypoint generates a self-signed RSA certificate valid for 365 days each time a fresh NGINX container starts. Test the endpoint and protocol from the VM:

```sh
curl --insecure --head --resolve akamamji.42.fr:443:127.0.0.1 https://akamamji.42.fr/
openssl s_client -connect 127.0.0.1:443 -servername akamamji.42.fr -tls1_2
openssl s_client -connect 127.0.0.1:443 -servername akamamji.42.fr -tls1_3
```

The certificate is for local evaluation, not public production use.

## Troubleshooting

### Docker socket permission denied

Confirm that Docker is running and that the current user is authorized to access its socket. Apply the VM's Docker group policy, then start a new login session after changing group membership.

### Port 443 is already allocated

Find the owning listener before stopping anything:

```sh
sudo ss -ltnp '( sport = :443 )'
```

Stop or reconfigure the conflicting service only if it is safe to do so.

### MariaDB is unhealthy

Check its logs and verify that `/home/akamamji/data/mysql` exists and is usable by Docker. A partially initialized directory can prevent a clean bootstrap; restore it from backup or, for disposable data only, recreate it from an empty state.

### WordPress cannot connect to MariaDB

Check `DB_NAME` and `WP_USER`, confirm the current database password matches `DB_PASSWORD` in the persisted `wp-config.php`, and verify both services are attached to the Compose network. Changing a secret file alone does not rotate an existing MariaDB account.

### NGINX returns 502 Bad Gateway

Confirm WordPress is healthy, PHP-FPM listens on `0.0.0.0:9000`, and the shared WordPress volume contains the requested PHP file. Then inspect both NGINX and WordPress logs.

### Configuration changes do not appear

Files copied by a Dockerfile are part of the image. Rebuild that image and recreate the service. WordPress and database content in volumes remain unchanged unless it is explicitly migrated or removed.

## Final validation checklist

- The three images build from their project Dockerfiles without `latest` tags.
- `docker compose ... ps` shows MariaDB and WordPress healthy and NGINX running.
- Only host port `443` is published.
- `https://akamamji.42.fr` serves the site and `/wp-admin/` accepts the configured administrator.
- TLS 1.2 and TLS 1.3 connect successfully.
- The administrator username contains neither `admin` nor `administrator`.
- Both WordPress users exist.
- Passwords exist only in ignored secret files, not in tracked sources or `.env`.
- Data survives `make stop` followed by `make run`.
- The named volumes point to the required `/home/akamamji/data` directories.
