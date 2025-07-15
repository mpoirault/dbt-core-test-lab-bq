{{
    config(
        materialized='incremental',
        unique_key='event_key',
        incremental_strategy='merge',
        partition_by={
            'field': 'event_date',
            'data_type': 'date',
        }
    )
}}

with fct_summary as (
    select * from {{ ref('fct_event_rsvp_summary') }}
    {% if is_incremental() %}
        where dbt_updated_at > (select max(dbt_updated_at) from {{ this }})
    {% endif %}
),

enriched_summary as (
    select
        -- Keys
        f.event_key,
        f.group_key,
        f.venue_key,
        
        -- Event Information
        e.event_name,
        e.series_number as event_series_number,
        e.description as event_description,
        e.original_status as event_original_status,
        e.current_status as event_current_status,
        e.duration_minutes as event_duration_minutes,
        e.rsvp_limit as event_rsvp_limit,
        
        -- Group Information
        g.group_name,
        g.topics as group_topics,
        
        -- Venue Information
        v.venue_name,
        v.city_name as venue_city_name,
        v.country_code as venue_country_code,
        v.latitude as venue_latitude,
        v.longitude as venue_longitude,
        
        -- Response Counts
        f.total_possible_responses,
        f.total_rsvp_responses,
        f.yes_responses,
        f.explicit_no_responses,
        f.waitlist_responses,
        f.total_guests,
        f.avg_days_before_event,
        f.total_no_responses,
        
        -- Response Rates (Original)
        f.rsvp_rate,
        f.yes_rate_of_responses,
        f.no_rate_of_responses,
        
        -- Response Rates (New)
        f.yes_rate,
        f.waitlist_rate,
        f.total_no_rate,
        f.explicit_no_rate,
        f.no_response_rate,
        
        -- Date and Time Fields
        f.event_time_ts,
        date(f.event_time_ts) as event_date,
        extract(year from f.event_time_ts) as event_year,
        extract(month from f.event_time_ts) as event_month,
        extract(day from f.event_time_ts) as event_day,
        extract(dayofweek from f.event_time_ts) as event_day_of_week,
        format_timestamp('%A', f.event_time_ts) as event_day_name,
        format_timestamp('%b', f.event_time_ts) as event_month_name,
        
        -- Metadata
        f.dbt_updated_at
        
    from fct_summary f
    join {{ ref('dim_events') }} e on f.event_key = e.event_id
    join {{ ref('dim_groups') }} g on f.group_key = g.group_id
    join {{ ref('dim_venues') }} v on f.venue_key = v.venue_id
)

select * from enriched_summary 