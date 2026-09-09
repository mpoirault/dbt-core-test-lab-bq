{#- Hardcoded, not dbt_utils.get_column_values: this model has a unit test,
    and unit tests never query the warehouse. -#}
{%- set payment_methods = ["bank_transfer", "coupon", "credit_card", "gift_card"] -%}

with

    stg_jaffle_shop__payments as (

        select order_id, payment_method, payment_status, amount_usd
        from {{ ref("stg_jaffle_shop__payments") }}

    ),

    successful_payments as (

        select order_id, payment_method, amount_usd
        from stg_jaffle_shop__payments
        where payment_status = 'success'

    ),

    pivoted as (

        select
            order_id,
            {{
                dbt_utils.pivot(
                    "payment_method",
                    payment_methods,
                    agg="sum",
                    then_value="amount_usd",
                    suffix="_amount_usd",
                    quote_identifiers=false,
                )
            }},
            sum(amount_usd) as total_amount_usd
        from successful_payments
        group by order_id

    )

select *
from pivoted
