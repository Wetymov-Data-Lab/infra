SELECT
    formatDateTime(created_at, '%d.%m.%Y %H:%i:%S.%f') AS time,
    service_name AS service,
    ifNull(actor_id, 'system') AS actor,
    action,
    resource_type,
    ifNull(resource_id, '—') AS resource_id,
    if(
        empty(JSONExtractString(context, 'request_id')),
        '—',
        JSONExtractString(context, 'request_id')
    ) AS request_id,
    ifNull(trace_id, '—') AS trace_id
FROM audit_log_view
WHERE ('__AUDIT_SERVICE__' = '' OR service_name = '__AUDIT_SERVICE__')
ORDER BY created_at DESC
LIMIT __AUDIT_LIMIT__
FORMAT PrettyCompactMonoBlock
SETTINGS output_format_pretty_max_value_width = 64;
