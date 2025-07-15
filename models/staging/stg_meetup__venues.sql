{{
    config(
        materialized='incremental',
        unique_key='venue_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'inserted_at_date',
            'data_type': 'date',
        },
        cluster_by=['venue_id']
    )
}}

with source as (
    select _partitiontime, * from {{ source('meetup', 'venues') }}
    {% if is_incremental() %}
        where _partitiontime > (select max(inserted_at_ts) from {{ this }})
    {% endif %}
),

-- Get the latest record for each venue based on _partitiontime
latest_venues as (
    select *
    from (
        select 
            *,
            row_number() over (
                partition by venue_id
                order by _partitiontime desc
            ) as row_num
        from source
    )
    where row_num = 1
),

renamed as (
    select
        -- ids
        cast(venue_id as string) as venue_id,

        -- strings
        {{clean_string('name')}} as venue_name,
        {{clean_city('city') }} as city_name,
        {{clean_string('country')}} as country_code,

        -- numerics
        case 
            when safe_cast(lat as float64) = 0 then null
            else safe_cast(lat as float64)
        end as latitude,
        case 
            when safe_cast(lon as float64) = 0 then null
            else safe_cast(lon as float64)
        end as longitude,

        -- timestamps & dates
        date(_partitiontime) as inserted_at_date,
        timestamp(_partitiontime) as inserted_at_ts,

        -- metadata
        current_timestamp() as _extracted_at_ts

    from latest_venues
    where venue_id is not null
),

final as (
    select 
        -- ids
        venue_id,
        
        -- strings
        venue_name,
        city_name,
        country_code,
        
        -- numerics
        latitude,
        longitude,
        
        -- timestamps & dates
        inserted_at_date,
        inserted_at_ts,
        
        -- metadata
        _extracted_at_ts
    from renamed
    where 
        not (venue_name is null 
            and city_name is null 
            and country_code is null)
)

select * from final
