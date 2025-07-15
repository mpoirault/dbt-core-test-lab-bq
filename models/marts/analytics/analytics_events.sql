{{
    config(
        materialized='incremental',
        unique_key='rsvp_key',
        incremental_strategy='merge',
        partition_by={
            'field': 'event_date',
            'data_type': 'date',
        }
    )
}}

with fact_event_rsvps as (
    select * from {{ ref('fct_event_rsvps') }}
    {% if is_incremental() %}
        where dbt_updated_at > (select max(dbt_updated_at) from {{ this }})
    {% endif %}
),

dim_events as (
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

analytics_events as (
    select
        -- Keys
        r.rsvp_key,
        r.event_key,
        r.user_key,
        r.group_key,
        r.venue_key,
        
        -- Event information
        e.event_name,
        e.series_number as event_series_number,
        e.original_status as event_original_status,
        e.current_status as event_current_status,
        e.description_length as event_description_length,
        e.has_description as event_has_description,
        e.duration_minutes as event_duration_minutes,
        e.duration_hours as event_duration_hours,
        e.rsvp_limit as event_rsvp_limit,
        
        -- RSVP information
        r.rsvp_response,
        r.guest_count as rsvp_guest_count,
        r.is_attending as rsvp_is_attending,
        r.has_guests as rsvp_has_guests,
        r.hours_before_event as rsvp_hours_before_event,
        r.days_before_event as rsvp_days_before_event,
        
        -- User information
        u.country_code as user_country_code,
        u.city_name as user_city_name,
        u.hometown_name as user_hometown_name,
        u.memberships as user_memberships,
        
        -- Group information
        g.group_name,
        g.description_length as group_description_length,
        g.has_description as group_has_description,
        g.has_valid_url as group_has_valid_url,
        g.latitude as group_latitude,
        g.longitude as group_longitude,
        g.topics as group_topics,
        
        -- Venue information
        v.venue_name,
        v.city_name as venue_city_name,
        v.country_code as venue_country_code,
        v.latitude as venue_latitude,
        v.longitude as venue_longitude,
        
        -- Date and time fields
        e.event_time_ts,
        date(e.event_time_ts) as event_date,
        extract(year from e.event_time_ts) as event_year,
        extract(month from e.event_time_ts) as event_month,
        extract(day from e.event_time_ts) as event_day,
        extract(dayofweek from e.event_time_ts) as event_day_of_week,
        format_timestamp('%A', e.event_time_ts) as event_day_name,
        format_timestamp('%b', e.event_time_ts) as event_month_name,
        
        r.rsvp_time_ts,
        r.rsvp_date,
        extract(year from r.rsvp_time_ts) as rsvp_year,
        extract(month from r.rsvp_time_ts) as rsvp_month,
        
        -- Metadata
        r.dbt_updated_at
        
    from fact_event_rsvps r
    join dim_events e on r.event_key = e.event_id
    join dim_users u on r.user_key = u.user_id
    join dim_groups g on r.group_key = g.group_id
    join dim_venues v on r.venue_key = v.venue_id
)

select * from analytics_events 