# Inception User Guide

This guide covers normal use of an already configured Inception installation. For first-time setup or maintenance, see [DEV_DOC.md](DEV_DOC.md).

## Services provided

The activity runs three containers:

- `nginx` provides the HTTPS website and is the only service reachable from the host, on port `443`.
- `wordpress` runs WordPress with PHP-FPM and creates the initial website accounts.
- `mariadb` stores WordPress content, users, and settings.

The website files and database remain available after the containers are stopped or recreated because they are stored in named volumes.

## Start the activity

Open a terminal in the repository root and run:

```sh
make run
```

The command returns after starting the containers in the background. The first launch takes longer because images must be built and WordPress must be initialized.

## Access the website

Open the following address in a browser:

```text
https://akamamji.42.fr
```

The hostname must resolve to the VM's IP address. A browser running inside the VM can normally use this `/etc/hosts` entry:

```text
127.0.0.1 akamamji.42.fr
```

For a browser on another machine, replace `127.0.0.1` with the VM's reachable IP address.

NGINX uses a locally generated, self-signed certificate. A browser warning is therefore expected. Accept it only after checking that the address points to your own VM.

## Access the administration panel

Open:

```text
https://akamamji.42.fr/wp-admin/
```

Sign in with:

- Username: the value of `WP_ADMIN` in `srcs/.env`.
- Password: the single line stored in `srcs/secrets/db_root_password.txt`.

Despite its legacy filename, `db_root_password.txt` is used by this implementation as the initial WordPress administrator password. The regular WordPress contributor uses the `WP_USER` name from `srcs/.env` and the password in `srcs/secrets/db_password.txt`.

## Credentials

Configuration and credentials are kept in two places:

- `srcs/.env` contains non-secret settings: hostname, database name, usernames, data directory, and MariaDB socket path.
- `srcs/secrets/db_password.txt` contains the MariaDB application-user password and initial WordPress contributor password.
- `srcs/secrets/db_root_password.txt` contains the initial WordPress administrator password.

These files are ignored by Git. Do not commit them, paste their contents into logs or commands, or send them to another person. On the host, restrict the files to their owner:

```sh
chmod 600 srcs/.env srcs/secrets/db_password.txt srcs/secrets/db_root_password.txt
```

Changing a file after the first successful launch does not automatically update accounts already stored in MariaDB or WordPress. Change WordPress passwords from the administration panel. Ask the stack administrator to coordinate database credential changes.

## Check service status

Run:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
```

The expected state is:

- `mariadb`: running and `healthy`.
- `wordpress`: running and `healthy`.
- `nginx`: running, with host port `443` mapped.

Test the HTTPS endpoint from the VM:

```sh
curl --insecure --head --resolve akamamji.42.fr:443:127.0.0.1 https://akamamji.42.fr/
```

An HTTP response such as `200`, `301`, or `302` confirms that NGINX is answering. `--insecure` is used only because the development certificate is self-signed.

If a service is missing, restarting, or unhealthy, inspect its recent logs:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=100 mariadb
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=100 wordpress
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=100 nginx
```

## Stop or restart the activity

Stop the containers cleanly:

```sh
make stop
```

The persistent website and database data are preserved. Start them again with `make run`.

Restart one service without stopping the whole stack:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env restart nginx
```

Replace `nginx` with `wordpress` or `mariadb` as needed.

## Common problems

### The hostname does not open

Check that `akamamji.42.fr` resolves to the VM and that port `443` is not blocked. The command below should show the intended IP:

```sh
getent hosts akamamji.42.fr
```

### The browser reports an insecure certificate

This is expected because the stack creates a self-signed certificate. Verify the hostname and VM before accepting it.

### Docker reports permission denied

Your user cannot access the Docker daemon. Use the VM's approved Docker setup or ask its administrator to grant Docker access, then sign out and back in if group membership changed.

### The site shows a database or gateway error

Run the status and log commands above. MariaDB must become healthy before WordPress starts, and WordPress must become healthy before NGINX starts.

## Destructive cleanup warning

`make fclean` is not a normal stop command. It runs global Docker prune operations and may remove unrelated unused Docker resources. Use `make stop` unless a full cleanup is explicitly required and you have reviewed [DEV_DOC.md](DEV_DOC.md).
