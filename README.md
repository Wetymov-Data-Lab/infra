## @wdl/infra

<details>
<summary><strong>Start infrastructure</strong></summary>

```sh
make up
```

Скрипты приложений, запущенных в Docker, подключаются к PostgreSQL по адресу
`postgres:5432` через общую сеть `vendor-network`.

Чтобы создать отдельного пользователя и принадлежащую ему базу данных:

```sh
docker compose exec postgres create_db_psql.sh \
  <user_name> <user_password> <database_name>
```

Вызов срабатывания скрипта является идемпотентным
</details>

<details>
<summary><strong>Make commands</strong></summary>

| Команда        | Описание                                      | Выполняемая команда                              |
|----------------|-----------------------------------------------|--------------------------------------------------|
| `make help`    | Показать список доступных команд              | Вывод справки из `Makefile`                      |
| `make env`     | Создать `.env`, если он отсутствует           | `test -f .env \|\| cp .env.example .env`         |
| `make up`      | Запустить сервисы в фоновом режиме            | `make env`, затем `docker compose up -d`         |
| `make down`    | Остановить и удалить контейнеры и сеть        | `docker compose down`                            |
| `make stop`    | Остановить контейнеры без их удаления         | `docker compose stop`                            |
| `make restart` | Перезапустить контейнеры                      | `docker compose restart`                         |
| `make logs`    | Показывать логи сервисов в реальном времени   | `docker compose logs -f`                         |
| `make ps`      | Показать состояние сервисов                   | `docker compose ps`                              |
| `make pull`    | Загрузить образы сервисов                     | `docker compose pull`                            |
| `make config`  | Проверить и вывести итоговую конфигурацию     | `docker compose config`                          |

`make down` не удаляет тома с данными PostgreSQL и Redis.
</details>
