# @wdl/infra

Локальная инфраструктура WDL и конвейер централизованного audit log.

## Как устроен проект

```text
PostgreSQL audit_log
  -> Debezium (CDC)
  -> Kafka topics
  -> ClickHouse Kafka Engine
  -> audit_log или audit_log_dead_letter
  -> MinIO после окончания hot-retention
```

- PostgreSQL хранит исходные audit-записи каждого приложения.
- Debezium читает изменения `public.audit_log` через logical replication.
- Kafka передаёт события между Debezium и ClickHouse.
- ClickHouse предоставляет общее представление `audit_log_view` для чтения.
- MinIO используется ClickHouse как cold storage, а не как самостоятельный архив JSON.

## Структура файлов

```text
clickhouse/
  config.d/storage.xml       # hot/cold storage policy
  init.sh                    # проверяет параметры и запускает SQL-шаблоны
  sql/*.sql.tpl              # создание БД, таблиц, очереди, consumers и view
  queries/*.sql.tpl          # запросы для make audit-*
debezium/
  register-connectors.sh     # регистрирует Core и Identity connectors
  templates/*.json.tpl       # декларативная конфигурация connector
helpers/
  audit/                     # просмотр и smoke-test audit pipeline
  db/                        # создание пользователя и базы PostgreSQL
kafka/init.sh                # создаёт audit topics
minio/init.sh                # создаёт bucket для cold storage
postgres/pg_hba.conf         # доступ PostgreSQL и logical replication
docker-compose.yml           # связи и порядок запуска сервисов
```

Файлы с расширением `.tpl` являются шаблонами. Их placeholders заполняют init-скрипты;
напрямую передавать такие файлы SQL- или JSON-клиенту не нужно.

## Запуск

Требуются Docker с Compose и утилита `make`.

```sh
make env
make up
make ps
```

`.env.example` содержит настройки только для локальной разработки. Перед использованием
в другом окружении необходимо заменить пароли и проверить опубликованные порты.

Сеть `vendor-network` создаётся целью `network` автоматически. Она объявлена внешней,
поэтому `make down` удаляет контейнеры, но сохраняет эту сеть и постоянные volumes.

Приложения должны применить миграции с таблицей `public.audit_log` в базах Core и
Identity. После этого состояние всего CDC-контура проверяется командой:

```sh
make audit-smoke
```

## Доступ с хоста

| Сервис | Адрес по умолчанию |
|---|---|
| PostgreSQL | `127.0.0.1:5432` |
| Redis | `127.0.0.1:6379` |
| MinIO API | `127.0.0.1:9000` |
| MinIO Console | `http://127.0.0.1:9001` |
| Kafka | `127.0.0.1:9094` |
| Debezium | `http://127.0.0.1:8083` |
| ClickHouse HTTP | `http://127.0.0.1:8123` |
| ClickHouse native | `127.0.0.1:9002` |

Внутри Docker-сети сервисы обращаются друг к другу по именам Compose-сервисов,
например `postgres:5432`, `kafka:9092` и `clickhouse:9000`.

## Конфигурация

Переменные в `.env` разделены по одной ответственности:

- `Runtime` — сеть, restart policy и healthchecks;
- `PostgreSQL`, `Redis`, `MinIO`, `Kafka`, `Debezium`, `ClickHouse` — параметры конкретного сервиса;
- `Application databases` — имена баз Core и Identity;
- `Audit retention` — сроки хранения основных и ошибочных событий.

`*_BIND_HOST` определяет интерфейс хоста, а `*_PUBLISHED_PORT` — опубликованный порт.
Порты внутри Docker-сети от этих значений не меняются.
`KAFKA_NUM_PARTITIONS` применяется при создании новых topics; Kafka не позволяет
уменьшить количество разделов уже существующего topic.

## Audit log

Показать последние 100 событий:

```sh
make audit-query
```

Доступны фильтр, лимит и период обновления:

```sh
make audit-query AUDIT_SERVICE=wdl-be-core AUDIT_LIMIT=20
make audit-watch AUDIT_SERVICE=wdl-be-identity AUDIT_REFRESH_SECONDS=5
make audit-errors AUDIT_LIMIT=20
```

`audit-errors` читает dead-letter таблицу — туда попадают CDC-сообщения с неверным
UUID, временем или пустым `service_name`.

## Команды

| Команда | Назначение |
|---|---|
| `make help` | Показать актуальный список команд из Makefile |
| `make env` | Создать `.env` из `.env.example`, если файла ещё нет |
| `make up` | Создать сеть и запустить инфраструктуру |
| `make down` | Удалить контейнеры, сохранив внешнюю сеть и volumes |
| `make stop` | Остановить контейнеры без удаления |
| `make restart` | Перезапустить контейнеры |
| `make logs` | Следить за логами всех сервисов |
| `make ps` | Показать состояние сервисов |
| `make pull` | Загрузить Docker images |
| `make config` | Проверить и вывести итоговый Compose config |
| `make cdc-status` | Показать состояние Debezium connectors |
| `make kafka-topics` | Показать Kafka topics |
| `make audit-query` | Вывести последние audit-события таблицей |
| `make audit-watch` | Периодически обновлять таблицу audit-событий |
| `make audit-errors` | Показать сообщения из dead-letter таблицы |
| `make audit-smoke` | Проверить PostgreSQL → Kafka → ClickHouse |

Для создания прикладной базы и её пользователя:

```sh
docker compose exec postgres create_db_psql.sh \
  <user_name> <user_password> <database_name>
```

Команда идемпотентна: повторный запуск обновляет пароль и владельца базы.

## Диагностика

1. Выполнить `make ps` и убедиться, что постоянные сервисы healthy.
2. Выполнить `make cdc-status`; connector и его task должны иметь статус `RUNNING`.
3. Выполнить `make kafka-topics` и проверить topics из `KAFKA_AUDIT_TOPICS`.
4. Выполнить `make audit-errors` для проверки отбракованных сообщений.
5. Выполнить `make audit-smoke` для проверки полного пути события.

Init-сервисы (`minio-init`, `kafka-init`, `debezium-init`, `clickhouse-init`) должны
завершаться с кодом `0`; состояние `Exited (0)` для них является нормальным.
