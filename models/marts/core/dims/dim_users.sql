{{
    config(
        materialized='incremental',
        unique_key='user_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'record_created_date',
            'data_type': 'date',
        },
        cluster_by=['user_id']
    )
}}

with source_users as (
    select * from {{ ref('stg_meetup__users') }}
    {% if is_incremental() %}
        where inserted_at_ts > (select max(record_created_ts) from {{ this }})
    {% endif %}
),

enriched_users as (
    select
        -- Key
        u.user_id,
        
        -- Location Information
        u.country_code,
        u.city_name,
        u.hometown_name,
        
        -- Group Memberships
        u.memberships,
        
        -- Timestamps
        u.inserted_at_ts as record_created_ts,
        date(u.inserted_at_ts) as record_created_date,
        
        -- Metadata
        current_timestamp() as dbt_updated_at
        
    from source_users u
)

select * from enriched_users 