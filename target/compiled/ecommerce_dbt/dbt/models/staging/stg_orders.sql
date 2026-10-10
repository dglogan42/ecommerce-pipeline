with source as (
    select * from "ecommerce"."raw"."orders"
)

select
    order_id,
    customer_id,
    order_date::date as order_date,
    status
from source