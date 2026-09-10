-- Recreate the Kafka consumer layer so configuration changes are applied.
-- Persistent audit tables are intentionally left untouched.
DROP VIEW IF EXISTS __CLICKHOUSE_DB__.audit_log_view;
DROP TABLE IF EXISTS __CLICKHOUSE_DB__.audit_log_consumer;
DROP TABLE IF EXISTS __CLICKHOUSE_DB__.audit_log_dead_letter_consumer;
DROP TABLE IF EXISTS __CLICKHOUSE_DB__.audit_log_queue;

CREATE TABLE __CLICKHOUSE_DB__.audit_log_queue
(
    message String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = '__KAFKA_AUDIT_TOPICS__',
    kafka_group_name = 'clickhouse-audit-log-v1',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_thread_per_consumer = 1;
