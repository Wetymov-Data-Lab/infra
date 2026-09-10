#!/bin/bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
connector_template="$script_dir/templates/postgres-audit-connector.json.tpl"

valid_identifier='^[a-zA-Z_][a-zA-Z0-9_]*$'
valid_hostname='^[a-zA-Z0-9.-]+$'
valid_number='^[0-9]+$'

[[ "$POSTGRES_HOSTNAME" =~ $valid_hostname ]] || { echo "Invalid PostgreSQL hostname" >&2; exit 2; }
[[ "$POSTGRES_PORT" =~ $valid_number ]] || { echo "Invalid PostgreSQL port" >&2; exit 2; }
[[ "$POSTGRES_USER" =~ $valid_identifier ]] || { echo "Invalid PostgreSQL user" >&2; exit 2; }
[[ "$CORE_POSTGRES_DB" =~ $valid_identifier ]] || { echo "Invalid core database" >&2; exit 2; }
[[ "$IDENTITY_POSTGRES_DB" =~ $valid_identifier ]] || { echo "Invalid identity database" >&2; exit 2; }
[[ "$DEBEZIUM_HEARTBEAT_INTERVAL_MS" =~ $valid_number ]] || { echo "Invalid heartbeat interval" >&2; exit 2; }
[[ "$KAFKA_NUM_PARTITIONS" =~ $valid_number ]] || { echo "Invalid topic partition count" >&2; exit 2; }

render_connector_config() {
    local database_name=$1
    local topic_prefix=$2
    local slot_name=$3
    local publication_name=$4

    sed \
        -e "s|__POSTGRES_HOSTNAME__|$POSTGRES_HOSTNAME|g" \
        -e "s|__POSTGRES_PORT__|$POSTGRES_PORT|g" \
        -e "s|__POSTGRES_USER__|$POSTGRES_USER|g" \
        -e "s|__DATABASE_NAME__|$database_name|g" \
        -e "s|__TOPIC_PREFIX__|$topic_prefix|g" \
        -e "s|__SLOT_NAME__|$slot_name|g" \
        -e "s|__PUBLICATION_NAME__|$publication_name|g" \
        -e "s|__HEARTBEAT_INTERVAL_MS__|$DEBEZIUM_HEARTBEAT_INTERVAL_MS|g" \
        -e "s|__TOPIC_PARTITIONS__|$KAFKA_NUM_PARTITIONS|g" \
        "$connector_template"
}

register_connector() {
    local connector_name=$1
    local database_name=$2
    local topic_prefix=$3
    local slot_name=$4
    local publication_name=$5

    curl --fail --silent --show-error --output /dev/null \
        --request PUT \
        --header "Content-Type: application/json" \
        --data @- \
        "$DEBEZIUM_CONNECT_URL/connectors/$connector_name/config" \
        < <(render_connector_config "$database_name" "$topic_prefix" "$slot_name" "$publication_name")
    curl --fail --silent --show-error --output /dev/null \
        --request POST \
        "$DEBEZIUM_CONNECT_URL/connectors/$connector_name/restart?includeTasks=true&onlyFailed=true"
    echo "Connector $connector_name configured"
}

register_connector "wdl-core-audit" "$CORE_POSTGRES_DB" "wdl-core" "wdl_core_audit" "wdl_core_audit"
register_connector \
    "wdl-identity-audit" \
    "$IDENTITY_POSTGRES_DB" \
    "wdl-identity" \
    "wdl_identity_audit" \
    "wdl_identity_audit"
