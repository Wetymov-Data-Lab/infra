SELECT
    formatDateTime(ingested_at, '%d.%m.%Y %H:%i:%S') AS time,
    reason,
    replaceOne(cdc_topic, '.public.audit_log', '') AS source,
    concat(toString(cdc_partition), ':', toString(cdc_offset)) AS position,
    left(raw_message, 80) AS message
FROM audit_log_dead_letter
ORDER BY ingested_at DESC
LIMIT __AUDIT_LIMIT__
FORMAT PrettyCompactMonoBlock
SETTINGS output_format_pretty_max_value_width = 80;
