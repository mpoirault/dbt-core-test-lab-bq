{{
    config(
        materialized='incremental',
        unique_key='event_key',
        partition_by={
            'field': 'event_time_ts',
            'data_type': 'timestamp',
        },
        cluster_by=['event_key']
    )
}}

with membership_totals as (
    select 
        group_membership.group_id as group_id,
        count(distinct user_id) as total_possible_responses
    from {{ ref('dim_users') }},
    unnest(memberships) as group_membership
    group by 1
),

rsvp_stats as (
    select
        -- Keys
        e.event_id as event_key,
        e.group_id as group_key,
        e.venue_id as venue_key,
        e.event_time_ts,
        
        -- RSVP Metrics (Original)
        count(distinct r.user_id) as total_rsvp_responses,
        count(distinct case when r.response = 'yes' then r.user_id end) as yes_responses,
        count(distinct case when r.response = 'no' then r.user_id end) as explicit_no_responses,
        count(distinct case when r.response = 'waitlist' then r.user_id end) as waitlist_responses,
        sum(r.guests) as total_guests,
        avg(timestamp_diff(e.event_time_ts, r.responded_ts, DAY)) as avg_days_before_event
    from {{ ref('dim_events') }} e
    left join unnest(e.rsvps) as r
    group by 1,2,3,4
)

select
    -- Keys
    r.event_key,
    r.group_key,
    r.venue_key,
    r.event_time_ts,
    
    -- Base Metrics (Original)
    m.total_possible_responses,
    r.total_rsvp_responses,
    r.yes_responses,
    r.explicit_no_responses,
    r.waitlist_responses,
    r.total_guests,
    r.avg_days_before_event,
    
    -- Original Calculated Metrics (keeping for backward compatibility)
    round(r.total_rsvp_responses / nullif(m.total_possible_responses, 0), 3) as rsvp_rate,
    round(r.yes_responses / nullif(r.total_rsvp_responses, 0), 3) as yes_rate_of_responses,
    round(r.explicit_no_responses / nullif(r.total_rsvp_responses, 0), 3) as no_rate_of_responses,
    
    -- New Metrics (based on total possible responses)
    (m.total_possible_responses - r.yes_responses - r.waitlist_responses) as total_no_responses,  -- includes both explicit 'no' and non-responses
    
    -- New Calculated Metrics (as rates of total possible responses)
    round(r.yes_responses / nullif(m.total_possible_responses, 0), 3) as yes_rate,
    round(r.waitlist_responses / nullif(m.total_possible_responses, 0), 3) as waitlist_rate,
    round((m.total_possible_responses - r.yes_responses - r.waitlist_responses) / 
        nullif(m.total_possible_responses, 0), 3) as total_no_rate,
    round(r.explicit_no_responses / nullif(m.total_possible_responses, 0), 3) as explicit_no_rate,
    round((m.total_possible_responses - r.total_rsvp_responses) / 
        nullif(m.total_possible_responses, 0), 3) as no_response_rate,
        
    -- Metadata
    current_timestamp() as dbt_updated_at
from rsvp_stats r
left join membership_totals m
    on r.group_key = m.group_id 