{{
    config(
        materialized='incremental',
        unique_key='venue_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'record_created_date',
            'data_type': 'date',
        },
        cluster_by=['venue_id']
    )
}}

with source_venues as (
    select * from {{ ref('stg_meetup__venues') }}
    {% if is_incremental() %}
        where inserted_at_ts > (select max(record_created_ts) from {{ this }})
    {% endif %}
),

enriched_venues as (
    select        
        -- Key
        v.venue_id,
        
        -- Descriptive Information
        v.venue_name,
        
        -- Location Information
        v.city_name,
        v.country_code,
        v.latitude,
        v.longitude,
        
        -- Timestamps
        v.inserted_at_ts as record_created_ts,
        date(v.inserted_at_ts) as record_created_date,
        
        -- Metadata
        current_timestamp() as dbt_updated_at
        
    from source_venues v
)

select * from enriched_venues 