{{
    config(
        materialized='incremental',
        unique_key='group_id',
        incremental_strategy='merge',
        partition_by={
            'field': 'inserted_at_date',
            'data_type': 'date',
        },
        cluster_by=['group_id']
    )
}}

with source as (
    select _partitiontime, * from {{ source('meetup', 'groups') }}
    {% if is_incremental() %}
        where _partitiontime > (select max(inserted_at_ts) from {{ this }})
    {% endif %}
),

-- Get the latest record for each group based on _partitiontime
latest_groups as (
    select *
    from (
        select 
            *,
            row_number() over (
                partition by group_id 
                order by _partitiontime desc
            ) as row_num
        from source
    )
    where row_num = 1
),

renamed as (
    select
        -- ids
        cast(group_id as string) as group_id,

        -- strings
        {{clean_string('name')}} as group_name,
        {{clean_string('description')}} as description,
        {{clean_string('link')}} as link,
        
        -- derived metrics
        length(description) as description_length,
        case 
            when description is null then false 
            else true 
        end as has_description,
        case
            when link is null then false
            when lower(link) like 'http%' then true
            else false
        end as has_valid_url,
        
        -- arrays
        array(
            select {{clean_string('topic')}}
            from unnest(topics) as topic
            where topic is not null
                and length(trim(topic)) > 0
        ) as topics,

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

    from latest_groups
    where group_id is not null
),

final as (
    select 
        -- ids
        group_id,
        
        -- strings
        group_name,
        description, 
        link,
        
        -- derived metrics
        description_length,
        has_description,
        has_valid_url,
        
        -- numerics
        latitude,
        longitude,
        
        -- arrays
        topics,
        
        -- timestamps & dates
        inserted_at_date,
        inserted_at_ts,
        
        -- metadata
        _extracted_at_ts
    from renamed
)

select * from final
