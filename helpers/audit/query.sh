#!/bin/bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
infra_dir=$(cd -- "$script_dir/../.." && pwd)
cd "$infra_dir"

mode=${1:-recent}
limit=${2:-100}
service=${3:-}
refresh_seconds=${4:-2}

[[ "$limit" =~ ^[1-9][0-9]*$ ]] || {
    echo "AUDIT_LIMIT must be a positive integer" >&2
    exit 2
}
[[ "$service" =~ ^[a-zA-Z0-9._-]*$ ]] || {
    echo "Invalid AUDIT_SERVICE" >&2
    exit 2
}
[[ "$refresh_seconds" =~ ^[1-9][0-9]*$ ]] || {
    echo "AUDIT_REFRESH_SECONDS must be a positive integer" >&2
    exit 2
}
run_query() {
    docker compose exec -T clickhouse bash -c \
        'clickhouse-client --database "$CLICKHOUSE_DB" --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD"'
}

show_recent() {
    sed \
        -e "s|__AUDIT_LIMIT__|$limit|g" \
        -e "s|__AUDIT_SERVICE__|$service|g" \
        clickhouse/queries/recent.sql.tpl | run_query
}

case "$mode" in
    recent)
        show_recent
        ;;
    watch)
        while true; do
            printf '\033[2J\033[H'
            show_recent
            sleep "$refresh_seconds"
        done
        ;;
    errors)
        sed \
            -e "s|__AUDIT_LIMIT__|$limit|g" \
            clickhouse/queries/errors.sql.tpl | run_query
        ;;
    *)
        echo "Unknown audit query: $mode" >&2
        exit 2
        ;;
esac
