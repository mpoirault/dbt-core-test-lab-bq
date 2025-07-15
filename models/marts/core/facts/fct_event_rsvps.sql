{{
    config(
        materialized='incremental',
        unique_key='rsvp_key',
        partition_by={
            'field': 'rsvp_date',
            'data_type': 'date',
        },
        cluster_by=['rsvp_key']
    )
}}

with dim_events as (
    select * from {{ ref('dim_events') }}
),

dim_users as (
    select * from {{ ref('dim_users') }}
),

dim_groups as (
    select * from {{ ref('dim_groups') }}
),

dim_venues as (
    select * from {{ ref('dim_venues') }}
),

unnested_rsvps as (
    select
        e.event_id,
        e.venue_id,
        e.group_id,
        e.event_time_ts,
        e.rsvp_limit,  -- This is the event's RSVP limit, from the event record
        e.series_number,  -- Include series number from events
        r.user_id,
        r.response as rsvp_response,
        r.responded_ts as rsvp_time_ts,
        r.guests as guest_count,
        date(r.responded_ts) as rsvp_date
    from dim_events e,
    unnest(e.rsvps) as r
    where r.user_id is not null
),

enriched_rsvps as (
    select
        -- Surrogate Keys
        {{ dbt_utils.generate_surrogate_key(['ur.event_id', 'ur.user_id', 'ur.rsvp_time_ts']) }} as rsvp_key,
        
        -- Dimension References (Surrogate Keys)
        -- All references are guaranteed to exist based on data constraints
        ur.event_id as event_key,
        v.venue_id as venue_key,
        g.group_id as group_key,
        u.user_id as user_key,
        
        -- RSVP Measures/Facts
        ur.rsvp_response,
        ur.guest_count,
        ur.rsvp_limit,  -- Event's max RSVP capacity
        
        -- RSVP Date/Time
        ur.rsvp_time_ts,
        ur.rsvp_date,
        
        -- Event Series Information
        ur.series_number as event_series_number,
        
        -- Derived Metrics
        timestamp_diff(ur.event_time_ts, ur.rsvp_time_ts, HOUR) as hours_before_event,
        timestamp_diff(ur.event_time_ts, ur.rsvp_time_ts, DAY) as days_before_event,
        
        -- Flags (Pre-computed for analytical queries)
        case 
            when lower(ur.rsvp_response) = 'yes' then true
            else false
        end as is_attending,
        
        case
            when ur.guest_count > 0 then true
            else false
        end as has_guests,
        
        -- Metadata
        current_timestamp() as dbt_updated_at
    from unnested_rsvps ur
    -- User join: Every RSVP must have a corresponding user in dim_users
    -- Data constraint: All user_ids in event RSVPs exist in the users table
    join dim_users u 
        on ur.user_id = u.user_id
    
    -- Group join: Every event belongs to a group
    -- Data constraint: All events must have a valid group_id
    join dim_groups g 
        on ur.group_id = g.group_id
    
    -- Venue join: Every event has a venue
    -- Data constraint: All events must have a valid venue_id
    join dim_venues v 
        on ur.venue_id = v.venue_id
)

select * from enriched_rsvps

{% if is_incremental() %}
    where rsvp_date > (select max(rsvp_date) from {{ this }})
{% endif %} 