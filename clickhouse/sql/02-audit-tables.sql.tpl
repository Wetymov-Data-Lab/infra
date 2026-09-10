-- Valid audit events received from PostgreSQL through Debezium.
CREATE TABLE IF NOT EXISTS __CLICKHOUSE_DB__.audit_log
(
    id UUID,
    service_name LowCardinality(String),
    action LowCardinality(String),
    resource_type LowCardinality(String),
    resource_id Nullable(String),
    actor_id Nullable(String),
    input String,
    changes String,
    context String,
    trace_id Nullable(String),
    created_at DateTime64(6, 'UTC'),
    source_database LowCardinality(String),
    cdc_topic LowCardinality(String),
    cdc_partition Int32,
    cdc_offset Int64,
    ingested_at DateTime64(6, 'UTC') DEFAULT now64(6)
)
ENGINE = ReplacingMergeTree(ingested_at)
PARTITION BY toYYYYMM(created_at)
ORDER BY (service_name, toDate(created_at), created_at, id)
SETTINGS storage_policy = 'audit_hot_cold';

-- CDC messages which cannot be converted into an audit event.
CREATE TABLE IF NOT EXISTS __CLICKHOUSE_DB__.audit_log_dead_letter
(
    raw_message String,
    reason LowCardinality(String),
    cdc_topic LowCardinality(String),
    cdc_partition Int32,
    cdc_offset Int64,
    ingested_at DateTime64(6, 'UTC') DEFAULT now64(6)
)
ENGINE = MergeTree
ORDER BY (ingested_at, cdc_topic, cdc_partition, cdc_offset);

-- Apply retention on every init, including already existing tables.
ALTER TABLE __CLICKHOUSE_DB__.audit_log MODIFY TTL
    created_at + INTERVAL __AUDIT_HOT_RETENTION_DAYS__ DAY TO VOLUME 'cold',
    created_at + INTERVAL __AUDIT_TOTAL_RETENTION_DAYS__ DAY DELETE;

ALTER TABLE __CLICKHOUSE_DB__.audit_log_dead_letter MODIFY TTL
    ingested_at + INTERVAL __AUDIT_ERROR_RETENTION_DAYS__ DAY DELETE;
