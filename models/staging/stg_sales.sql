{{
    config(
        materialized='view',
    )
}}

with source as (

    select * from {{ source('raw', 'sales') }}

),

renamed as (

    select
        *
    from source

)

select * from renamed