{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'inserted_at_date',
            'data_type': 'date',
        },
        cluster_by=['event_id']
    )
}}


with source as (
    select _partitiontime, * from {{ source('meetup', 'events') }}
    {% if is_incremental() %}
        where _partitiontime > (select max(inserted_at_ts) from {{ this }})
    {% endif %}
),

-- Get the latest record for each event based on _partitiontime
latest_events as (
    select *
    from (
        select 
            *,
            row_number() over (
                partition by venue_id, time, group_id, name, description
                order by _partitiontime desc
            ) as row_num
        from source
    )
    where row_num = 1
),

renamed as (
    select
        --surrogate key
        concat('venue_id', 'time', 'group_id', 'name', 'description') as event_id,

        -- ids
        cast(venue_id as string) as venue_id,
        cast(group_id as string) as group_id,

        -- strings
        {{clean_string('name')}} as event_name,
        {{clean_string('description')}} as description,
        {{clean_string('status')}} as original_status,
        
        -- derived status (data is extracted a while ago so most statuuses arent right )
        case 
            when status in ('cancelled', 'proposed', 'suggested') then {{clean_string('status')}}
            when timestamp_millis(cast(time as int64)) < current_timestamp() then 'past'
            else 'upcoming'
        end as current_status,

        -- derived description metrics
        length(description) as description_length,
        case 
            when description is null then false 
            else true 
        end as has_description,

        -- timestamps
        timestamp_millis(cast(time as int64)) as event_time_ts,
        timestamp_millis(cast(created as int64)) as event_created_ts,

        -- numerics
        cast(duration as int64) / 60 as duration_minutes,
        cast(duration as int64) / 3600 as duration_hours,
        cast(rsvp_limit as int64) as rsvp_limit,

        -- arrays/nested
        array(
            select as struct
                cast(r.user_id as string) as user_id,
                if(response is null, 'no', {{clean_string('response')}}) as response,
                timestamp_millis(cast(r.when as int64)) as responded_ts,
                cast(r.guests as int64) as guests
            from unnest(rsvps) as r
            where r.user_id is not null
        ) as rsvps,

        -- timestamps & dates
        date(_partitiontime) as inserted_at_date,
        timestamp(_partitiontime) as inserted_at_ts,

        -- metadata
        current_timestamp() as _extracted_at_ts

    from latest_events
    where venue_id is not null
      and group_id is not null
),

-- Calculate series numbers for events with the same name
with_series as (
    select
        *,
        row_number() over (
            partition by event_name 
            order by event_time_ts
        ) as series_number
    from renamed
),

final as (
    select 
        -- ids
        event_id,
        venue_id,
        group_id,
        
        -- strings
        event_name,
        description,
        original_status,
        current_status,
        
        -- derived metrics
        description_length,
        has_description,
        
        -- numerics
        duration_minutes,
        duration_hours,
        rsvp_limit,
        series_number,
        
        -- arrays
        rsvps,
        
        -- timestamps
        event_time_ts,
        event_created_ts,
        inserted_at_ts,
        inserted_at_date,
        
        -- metadata
        _extracted_at_ts
    from with_series
)

select * from final