INSERT INTO audit_log (
    id,
    service_name,
    action,
    resource_type,
    resource_id,
    actor_id,
    input,
    changes,
    context,
    trace_id,
    created_at
) VALUES (
    gen_random_uuid(),
    :'service_name',
    'audit.smoke-test',
    'infrastructure',
    'compose',
    NULL,
    '{"password": "***"}',
    NULL,
    '{}',
    NULL,
    now()
)
RETURNING id;
