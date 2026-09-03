#!/bin/bash
set -euo pipefail

show_usage() {
    echo "Создаёт пользователя PostgreSQL и принадлежащую ему базу данных."
    echo "Использование:"
    echo "create_db_psql.sh <user_name> <user_password> <database_name>"
}

if [[ $# -ne 3 ]]; then
    echo "Ошибка: ожидаются имя пользователя, пароль и имя базы данных." >&2
    echo >&2
    show_usage >&2
    exit 2
fi

user_name=$1
user_password=$2
database_name=$3

admin_user=${POSTGRES_USER:-postgres}
admin_database=${POSTGRES_DB:-postgres}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

psql \
    --username "$admin_user" \
    --dbname "$admin_database" \
    --set ON_ERROR_STOP=1 \
    --set user_name="$user_name" \
    --set user_password="$user_password" \
    --set database_name="$database_name" \
    --file "$script_dir/create_db_psql.sql"

echo "Пользователь '$user_name' и база '$database_name' готовы."
