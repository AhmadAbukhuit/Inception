.PHONY: run stop clean fclean

COMPOSE = docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env
DATA_PATH = /home/akamamji/data

run:
	mkdir -p "$(DATA_PATH)/wordpress" "$(DATA_PATH)/mysql"
	DATA_PATH="$(DATA_PATH)" $(COMPOSE) up -d --remove-orphans

stop:
	DATA_PATH="$(DATA_PATH)" $(COMPOSE) down --remove-orphans

clean:
	DATA_PATH="$(DATA_PATH)" $(COMPOSE) down --remove-orphans

fclean:
	DATA_PATH="$(DATA_PATH)" $(COMPOSE) down --remove-orphans --volumes --rmi all
	rm -rf "$(DATA_PATH)/wordpress" "$(DATA_PATH)/mysql"
