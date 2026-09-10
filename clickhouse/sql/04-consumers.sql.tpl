-- Store valid Debezium messages in the main audit table.
CREATE MATERIALIZED VIEW __CLICKHOUSE_DB__.audit_log_consumer
TO __CLICKHOUSE_DB__.audit_log
AS
WITH
    JSONExtractString(message, 'after', 'id') AS raw_id,
    parseDateTime64BestEffortOrNull(
        JSONExtractString(message, 'after', 'created_at'),
        6,
        'UTC'
    ) AS parsed_created_at
SELECT
    assumeNotNull(toUUIDOrNull(raw_id)) AS id,
    JSONExtractString(message, 'after', 'service_name') AS service_name,
    JSONExtractString(message, 'after', 'action') AS action,
    JSONExtractString(message, 'after', 'resource_type') AS resource_type,
    nullIf(JSONExtractString(message, 'after', 'resource_id'), '') AS resource_id,
    nullIf(JSONExtractString(message, 'after', 'actor_id'), '') AS actor_id,
    if(empty(JSONExtractString(message, 'after', 'input')), 'null', JSONExtractString(message, 'after', 'input')) AS input,
    if(empty(JSONExtractString(message, 'after', 'changes')), 'null', JSONExtractString(message, 'after', 'changes')) AS changes,
    if(empty(JSONExtractString(message, 'after', 'context')), '{}', JSONExtractString(message, 'after', 'context')) AS context,
    nullIf(JSONExtractString(message, 'after', 'trace_id'), '') AS trace_id,
    assumeNotNull(parsed_created_at) AS created_at,
    JSONExtractString(message, 'source', 'db') AS source_database,
    _topic AS cdc_topic,
    _partition AS cdc_partition,
    _offset AS cdc_offset,
    now64(6) AS ingested_at
FROM __CLICKHOUSE_DB__.audit_log_queue
WHERE JSONExtractString(message, 'op') IN ('c', 'r')
  AND isNotNull(toUUIDOrNull(raw_id))
  AND isNotNull(parsed_created_at)
  AND notEmpty(JSONExtractString(message, 'after', 'service_name'));

-- Preserve malformed messages for diagnosis instead of silently dropping them.
CREATE MATERIALIZED VIEW __CLICKHOUSE_DB__.audit_log_dead_letter_consumer
TO __CLICKHOUSE_DB__.audit_log_dead_letter
AS
WITH
    JSONExtractString(message, 'after', 'id') AS raw_id,
    parseDateTime64BestEffortOrNull(
        JSONExtractString(message, 'after', 'created_at'),
        6,
        'UTC'
    ) AS parsed_created_at
SELECT
    message AS raw_message,
    multiIf(
        isNull(toUUIDOrNull(raw_id)), 'invalid audit id',
        isNull(parsed_created_at), 'invalid created_at',
        'missing service_name'
    ) AS reason,
    _topic AS cdc_topic,
    _partition AS cdc_partition,
    _offset AS cdc_offset,
    now64(6) AS ingested_at
FROM __CLICKHOUSE_DB__.audit_log_queue
WHERE JSONExtractString(message, 'op') IN ('c', 'r')
  AND (
      isNull(toUUIDOrNull(raw_id))
      OR isNull(parsed_created_at)
      OR empty(JSONExtractString(message, 'after', 'service_name'))
  );
