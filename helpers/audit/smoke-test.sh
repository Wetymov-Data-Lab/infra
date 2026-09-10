#!/bin/bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
infra_dir=$(cd -- "$script_dir/../.." && pwd)
cd "$infra_dir"

compose=(docker compose)
max_attempts=30
retry_delay_seconds=1
postgres_user=$("${compose[@]}" exec -T postgres printenv POSTGRES_USER)
core_database=$("${compose[@]}" exec -T postgres printenv CORE_POSTGRES_DB)
identity_database=$("${compose[@]}" exec -T postgres printenv IDENTITY_POSTGRES_DB)

smoke_database() {
    local database_name=$1
    local service_name=$2
    local audit_id
    local count

    audit_id=$(
        "${compose[@]}" exec -T postgres \
            psql --username "$postgres_user" --dbname "$database_name" --tuples-only --no-align \
            --set ON_ERROR_STOP=1 \
            --set "service_name=$service_name" < "$script_dir/sql/insert.sql"
    )
    audit_id=$(printf '%s' "$audit_id" | head -n 1)
    [[ "$audit_id" =~ ^[0-9a-fA-F-]{36}$ ]] || {
        echo "PostgreSQL returned an invalid audit ID" >&2
        return 1
    }

    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        count=$(
            sed \
                -e "s|__AUDIT_ID__|$audit_id|g" \
                "$script_dir/sql/count.sql.tpl" | "${compose[@]}" exec -T clickhouse bash -c \
                    'clickhouse-client --database "$CLICKHOUSE_DB" --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD"'
        )
        if [[ "$count" == "1" ]]; then
            echo "Audit pipeline for $database_name is healthy: $audit_id"
            return 0
        fi
        sleep "$retry_delay_seconds"
    done

    echo "Audit record $audit_id from $database_name did not reach ClickHouse" >&2
    return 1
}

smoke_database "$core_database" "wdl-be-core-smoke-test"
smoke_database "$identity_database" "wdl-be-identity-smoke-test"
