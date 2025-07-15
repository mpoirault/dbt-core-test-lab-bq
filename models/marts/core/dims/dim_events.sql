{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'record_created_date',
            'data_type': 'date',
        },
        cluster_by=['event_id']
    )
}}

with source_events as (
    select * from {{ ref('stg_meetup__events') }}
    {% if is_incremental() %}
        where inserted_at_ts > (select max(record_created_ts) from {{ this }})
    {% endif %}
),

enriched_events as (
    select        
        -- Key
        e.event_id,
        
        -- Foreign Keys
        e.venue_id,
        e.group_id,
        
        -- Descriptive Information
        e.event_name,
        e.series_number,
        e.description,
        e.original_status,
        e.current_status,
        e.description_length,
        e.has_description,
        
        -- Event Details
        e.duration_minutes,
        e.duration_hours,
        e.rsvp_limit,
        
        -- RSVP Information
        e.rsvps,
        
        -- Event Timestamps
        e.event_time_ts,
        e.event_created_ts,
        e.inserted_at_ts as record_created_ts,
        date(e.inserted_at_ts) as record_created_date,
        
        -- Metadata
        current_timestamp() as dbt_updated_at
        
    from source_events e
)

select * from enriched_events 