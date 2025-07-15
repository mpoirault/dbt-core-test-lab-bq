{{
    config(
        materialized='incremental',
        unique_key='user_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'inserted_at_date',
            'data_type': 'date',
        },
        cluster_by=['user_id']
    )
}}


with source as (
    select _partitiontime, * from {{ source('meetup', 'users') }}
    {% if is_incremental() %}
        where _partitiontime > (select max(inserted_at_ts) from {{ this }})
    {% endif %}
),

-- Get the latest record for each user based on _partitiontime
latest_users as (
    select *
    from (
        select 
            *,
            row_number() over (
                partition by user_id
                order by _partitiontime desc
            ) as row_num
        from source
    )
    where row_num = 1
),

renamed as (
    select
        -- ids
        cast(user_id as string) as user_id,

        -- strings
        {{clean_string('country')}} as country_code,
        {{clean_string('city')}} as city_name,
        {{clean_hometown('hometown')}} as hometown_name,

        -- arrays/nested
        array(
            select as struct
                cast(m.group_id as string) as group_id,
                timestamp_millis(cast(m.joined as int64)) as joined_ts
            from unnest(memberships) as m
            where m.group_id is not null
                and m.joined is not null
        ) as memberships,

        -- timestamps & dates
        date(_partitiontime) as inserted_at_date,
        timestamp(_partitiontime) as inserted_at_ts,

        -- metadata
        current_timestamp() as _extracted_at_ts

    from latest_users
    where user_id is not null
),

final as (
    select 
        -- ids
        user_id,
        
        -- strings
        country_code,
        city_name,
        hometown_name,

        -- arrays/nested
        memberships,
        
        -- timestamps & dates
        inserted_at_date,
        inserted_at_ts,
        
        -- metadata
        _extracted_at_ts
    from renamed
)

select * from final
