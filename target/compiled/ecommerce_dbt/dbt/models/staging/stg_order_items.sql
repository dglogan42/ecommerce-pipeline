with source as (
    select * from "ecommerce"."raw"."order_items"
)

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price::numeric(10,2) as unit_price
from source