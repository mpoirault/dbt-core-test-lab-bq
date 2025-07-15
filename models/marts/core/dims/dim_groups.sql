{{
    config(
        materialized='incremental',
        unique_key='group_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'record_created_date',
            'data_type': 'date',
        },
        cluster_by=['group_id']
    )
}}

with source_groups as (
    select * from {{ ref('stg_meetup__groups') }}
    {% if is_incremental() %}
        where inserted_at_ts > (select max(record_created_ts) from {{ this }})
    {% endif %}
),

enriched_groups as (
    select        
        -- Key
        g.group_id,
        
        -- Descriptive Information
        g.group_name,
        g.description,
        g.description_length,
        g.has_description,
        
        -- Web Information
        g.link,
        g.has_valid_url,
        
        -- Location Information
        g.latitude,
        g.longitude,
        
        -- Topics/Categories
        g.topics,
        
        -- Timestamps
        g.inserted_at_ts as record_created_ts,
        date(g.inserted_at_ts) as record_created_date,
        
        -- Metadata
        current_timestamp() as dbt_updated_at
        
    from source_groups g
)

select * from enriched_groups 