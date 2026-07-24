COMPOSE := docker compose

.PHONY: help env up down stop restart logs ps pull config

help:
	@echo "Доступные команды:"
	@echo "  make env      — создать .env из .env.example"
	@echo "  make up       — запустить сервисы в фоне"
	@echo "  make down     — остановить и удалить контейнеры и сеть"
	@echo "  make stop     — остановить контейнеры"
	@echo "  make restart  — перезапустить контейнеры"
	@echo "  make logs     — показать логи"
	@echo "  make ps       — показать состояние сервисов"
	@echo "  make pull     — загрузить образы"
	@echo "  make config   — проверить и вывести конфигурацию"

env:
	@test -f .env || cp .env.example .env

up: env
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

pull:
	$(COMPOSE) pull

config:
	$(COMPOSE) config
