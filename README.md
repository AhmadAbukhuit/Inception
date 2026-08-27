*This activity has been created as part of the 42 curriculum by akamamji.*

# Inception

## Description

Inception is a system-administration activity that builds a small web infrastructure with Docker Compose inside a virtual machine. Its goal is to teach service isolation, image construction, container networking, TLS, secret handling, and persistent storage.

The stack contains three services, each built from its own Alpine-based Dockerfile and run in a dedicated container:

- **NGINX** is the only public entry point. It listens on host port `443`, accepts TLS 1.2 and TLS 1.3, serves static WordPress files, and forwards PHP requests to PHP-FPM.
- **WordPress + PHP-FPM** provides the website and creates the initial administrator and contributor accounts. It is reachable only inside the Compose network on port `9000`.
- **MariaDB** stores the WordPress database. It is reachable only inside the Compose network on port `3306`.

WordPress files and MariaDB data persist in Docker named volumes backed by `/home/akamamji/data/wordpress` and `/home/akamamji/data/mysql` on the host. All services share the private `inception` bridge network and use `restart: on-failure`.

```text
Browser
   |
   | HTTPS :443 (TLS 1.2/1.3)
   v
 NGINX ---- FastCGI :9000 ----> WordPress / PHP-FPM
                                      |
                                      | MariaDB protocol :3306
                                      v
                                   MariaDB
```

Only NGINX publishes a host port. The other ports are exposed for service-to-service communication, not published to the host.

## Project sources and design choices

The project is assembled from the following sources:

- `Makefile` provides the main lifecycle targets.
- `srcs/docker-compose.yml` declares services, health checks, secrets, the network, and volumes.
- `srcs/requirements/*/Dockerfile` builds each image from a pinned Alpine base image.
- `srcs/requirements/*/tools/main.sh` initializes each service and starts its main process with `exec`, making the daemon PID 1.
- `srcs/requirements/*/conf/` contains the NGINX, PHP-FPM, and MariaDB configuration and the database bootstrap template.
- `srcs/.env` supplies non-secret runtime configuration.
- `srcs/secrets/` supplies passwords as files mounted under `/run/secrets` in the authorized containers.

Important design choices include pinned base-image digests instead of `latest`, one responsibility per container, health-gated startup order, no host networking, no infinite-loop keepalive commands, a read-only WordPress mount in NGINX, and file-based passwords. NGINX creates a self-signed certificate when its container starts, so browsers will display a certificate warning in this local development environment.

### Virtual machines vs Docker

| Virtual machines | Docker containers |
| --- | --- |
| Virtualize hardware and run a complete guest operating system with its own kernel. | Isolate processes while sharing the host kernel. |
| Usually require more memory, disk space, and startup time. | Usually start faster and have a smaller resource footprint. |
| Provide a stronger, broader isolation boundary. | Package one service and its dependencies in a portable image. |

This activity uses both approaches: the whole project runs in a VM, while Docker isolates the three application services inside that VM.

### Secrets vs environment variables

| Environment variables | Secrets |
| --- | --- |
| Convenient for non-sensitive settings such as hostnames, database names, and filesystem paths. | Intended for sensitive values such as passwords. |
| Commonly visible through process/container inspection and inherited by child processes. | Granted only to selected services and mounted as files under `/run/secrets`. |

This project keeps `HOST`, `DB_NAME`, usernames, and service paths in `srcs/.env`. Passwords belong in the ignored files under `srcs/secrets/`; they must never be committed.

### Docker network vs host network

| Docker bridge network | Host network |
| --- | --- |
| Gives the stack an isolated network and built-in service-name discovery. | Makes a container share the host network namespace. |
| Allows only explicitly published ports to reach the host. | Reduces network isolation and can create direct port conflicts. |

The custom `inception` bridge lets WordPress reach `mariadb:3306` and NGINX reach `wordpress:9000`, while only NGINX publishes port `443`. Host networking is not used.

### Docker volumes vs bind mounts

| Docker named volumes | Direct bind mounts |
| --- | --- |
| Are declared and managed through Docker and referenced by a logical name. | Map an explicit host path directly into a service. |
| Decouple service definitions from ordinary host-file mounts and survive container replacement. | Are useful when host tools must edit the same files, but couple the container to a host path. |

The services consume the named volumes `wordpress-vol` and `mariadb-vol`. Their local-driver options place the backing data in the activity-required `/home/akamamji/data` directory; no service-level bind mount is declared.

## Instructions

### Prerequisites

- A Linux virtual machine.
- Docker Engine with the Docker Compose v2 plugin.
- GNU Make.
- Permission to use Docker and create `/home/akamamji/data`.
- Port `443` available on the VM.

For a complete first-time setup, including `.env`, secrets, host directories, and hostname resolution, read [DEV_DOC.md](DEV_DOC.md).

### Start the stack

From the repository root:

```sh
make run
```

On the first run, Compose builds the images, creates the network and volumes, initializes MariaDB and WordPress, and starts the containers in the background. Open:

```text
https://akamamji.42.fr
```

The local certificate is self-signed. Confirm the certificate warning only if the hostname resolves to your own VM.

### Stop the stack

```sh
make stop
```

This removes the containers and network but preserves the named volumes and website data. See [USER_DOC.md](USER_DOC.md) for routine use and status checks.

### Common commands

```sh
# Validate the resolved Compose configuration
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config --quiet

# Build or rebuild every image
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build

# Show service state and health
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps

# Follow logs from all services
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs -f
```

Do not use `make fclean` as a routine stop command. It kills this activity's containers and runs system-wide Docker prune commands that can remove unrelated unused images, volumes, and networks.

## Documentation

- [USER_DOC.md](USER_DOC.md) — starting, stopping, accessing, and checking the activity.
- [DEV_DOC.md](DEV_DOC.md) — first-time setup, configuration, administration, persistence, and troubleshooting.

## Resources

- [Docker: What is a container?](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker Compose networking](https://docs.docker.com/compose/how-tos/networking/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
- [Docker Compose secrets](https://docs.docker.com/reference/compose-file/secrets/)
- [NGINX HTTPS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WP-CLI command reference](https://developer.wordpress.org/cli/commands/)
- [MariaDB Server documentation](https://mariadb.com/docs/server/)

### Use of AI

AI assistance was used for this documentation update to extract the requirements from the subject, inspect the repository's Compose/Docker configuration, organize the guides, and check that the documented commands, paths, services, and credential roles match the implementation. The resulting text was reviewed against the project files; AI output should still be understood and verified by the project author before submission or evaluation.
