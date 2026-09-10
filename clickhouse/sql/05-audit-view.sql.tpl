-- Deduplicated read model used by audit-query and application tooling.
CREATE VIEW __CLICKHOUSE_DB__.audit_log_view AS
SELECT
    id,
    created_at,
    service_name,
    actor_id,
    action,
    resource_type,
    resource_id,
    input,
    changes,
    context,
    trace_id,
    source_database,
    ingested_at
FROM __CLICKHOUSE_DB__.audit_log FINAL;
