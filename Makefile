.PHONY:
run: ./srcs/docker-compose.yml
	docker compose  -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d

stop: ./srcs/docker-compose.yml
	docker compose  -f ./srcs/docker-compose.yml --env-file ./srcs/.env down

fclean:
	docker kill nginx wordpress mariadb || true && docker system prune -a && docker volume prune && docker network prune
