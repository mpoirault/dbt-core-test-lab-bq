{% macro log_bq_jobs(region='EU', dataset='dbt_audit', table='bq_job_log') %}

    INSERT INTO `max-poirault-sndbx-q.{{ dataset }}.{{ table }}`
    WITH jobs AS (
        SELECT *
        FROM   `region-{{ region }}`.INFORMATION_SCHEMA.JOBS
        WHERE  EXISTS (
            SELECT 1
            FROM   UNNEST(labels) l
            WHERE  l.key   = 'dbt_invocation_id'
            AND    l.value = '{{ invocation_id }}'
        )
    )
    SELECT
        '{{ invocation_id }}' AS invocation_id,
        job_id, user_email, state, statement_type,
        creation_time, start_time, end_time,
        (SELECT value FROM UNNEST(labels) WHERE key = 'node_id')       AS node_id,
        (SELECT value FROM UNNEST(labels) WHERE key = 'node_name')     AS node_name,
        (SELECT value FROM UNNEST(labels) WHERE key = 'resource_type') AS resource_type,
        (SELECT value FROM UNNEST(labels) WHERE key = 'package_name')  AS package_name,
        (SELECT value FROM UNNEST(labels) WHERE key = 'file')          AS file_path,
        (SELECT value FROM UNNEST(labels) WHERE key = 'profile_name')  AS profile_name,
        (SELECT value FROM UNNEST(labels) WHERE key = 'target_name')   AS target_name,
        total_bytes_billed, total_slot_ms, cache_hit, query
    FROM jobs;

{% endmacro %}
