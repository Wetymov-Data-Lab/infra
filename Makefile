COMPOSE := docker compose
AUDIT_LIMIT ?= 100
AUDIT_SERVICE ?=
AUDIT_REFRESH_SECONDS ?= 2

.PHONY: help env network up down stop restart logs ps pull config
.PHONY: cdc-status kafka-topics audit-query audit-watch audit-errors audit-smoke

help: ## показать доступные команды
	@awk 'BEGIN { FS = ":.*## " } /^[a-zA-Z0-9_-]+:.*## / { printf "  make %-14s — %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

env: ## создать .env из .env.example
	@test -f .env || cp .env.example .env

network: env
	@set -a; . ./.env; \
		docker network inspect "$$VENDOR_NETWORK_NAME" >/dev/null 2>&1 || \
		docker network create "$$VENDOR_NETWORK_NAME" >/dev/null

up: network ## запустить сервисы в фоне
	$(COMPOSE) up -d

down: ## остановить и удалить контейнеры
	$(COMPOSE) down

stop: ## остановить контейнеры
	$(COMPOSE) stop

restart: ## перезапустить контейнеры
	$(COMPOSE) restart

logs: ## показать логи
	$(COMPOSE) logs -f

ps: ## показать состояние сервисов
	$(COMPOSE) ps

pull: ## загрузить образы
	$(COMPOSE) pull

config: ## проверить конфигурацию
	$(COMPOSE) config

cdc-status: ## показать состояние Debezium connectors
	$(COMPOSE) exec -T debezium curl --fail --silent --show-error \
		http://localhost:8083/connectors?expand=status

kafka-topics: ## показать топики Kafka
	$(COMPOSE) exec -T kafka /opt/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 --list

audit-query: ## показать последние audit-записи
	@./helpers/audit/query.sh recent "$(AUDIT_LIMIT)" "$(AUDIT_SERVICE)"

audit-watch: ## периодически обновлять audit-таблицу
	@./helpers/audit/query.sh watch "$(AUDIT_LIMIT)" "$(AUDIT_SERVICE)" "$(AUDIT_REFRESH_SECONDS)"

audit-errors: ## показать ошибки обработки CDC
	@./helpers/audit/query.sh errors "$(AUDIT_LIMIT)"

audit-smoke: ## проверить PostgreSQL > Kafka > ClickHouse
	./helpers/audit/smoke-test.sh
