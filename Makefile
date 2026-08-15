.PHONY:
run: docker-compose.yml
	docker compose up -d

stop: docker-compose.yml
	docker compose down

fclean: docker system prune -a && docker volume prune && docker network prune
