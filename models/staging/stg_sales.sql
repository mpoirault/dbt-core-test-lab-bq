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
        product_id,
        name as product_name,
        category as product_category,
        price as product_price

    from source

)

select * from renamed