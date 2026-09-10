#!/bin/bash
set -euo pipefail

valid_name='^[a-zA-Z_][a-zA-Z0-9_]*$'
valid_days='^[0-9]+$'
valid_topics='^[a-zA-Z0-9._,-]+$'
[[ "$CLICKHOUSE_DB" =~ $valid_name ]] || { echo "Invalid CLICKHOUSE_DB" >&2; exit 2; }
[[ "$AUDIT_HOT_RETENTION_DAYS" =~ $valid_days ]] || { echo "Invalid hot retention" >&2; exit 2; }
[[ "$AUDIT_TOTAL_RETENTION_DAYS" =~ $valid_days ]] || { echo "Invalid total retention" >&2; exit 2; }
[[ "$AUDIT_ERROR_RETENTION_DAYS" =~ $valid_days ]] || { echo "Invalid error retention" >&2; exit 2; }
[[ "$KAFKA_AUDIT_TOPICS" =~ $valid_topics ]] || { echo "Invalid Kafka audit topics" >&2; exit 2; }

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

render_template() {
    sed \
        -e "s|__CLICKHOUSE_DB__|$CLICKHOUSE_DB|g" \
        -e "s|__AUDIT_HOT_RETENTION_DAYS__|$AUDIT_HOT_RETENTION_DAYS|g" \
        -e "s|__AUDIT_TOTAL_RETENTION_DAYS__|$AUDIT_TOTAL_RETENTION_DAYS|g" \
        -e "s|__AUDIT_ERROR_RETENTION_DAYS__|$AUDIT_ERROR_RETENTION_DAYS|g" \
        -e "s|__KAFKA_AUDIT_TOPICS__|$KAFKA_AUDIT_TOPICS|g" \
        "$1"
}

apply_template() {
    echo "Applying $(basename "$1")"
    render_template "$1" | clickhouse-client \
        --host clickhouse \
        --user "$CLICKHOUSE_USER" \
        --password "$CLICKHOUSE_PASSWORD" \
        --multiquery
}

for sql_template in "$script_dir"/sql/*.sql.tpl; do
    apply_template "$sql_template"
done
