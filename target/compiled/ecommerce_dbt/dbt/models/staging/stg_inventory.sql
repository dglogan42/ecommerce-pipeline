with source as (
    select * from "ecommerce"."raw"."inventory"
)

select
    product_id,
    quantity_on_hand,
    last_updated::timestamp as last_updated
from source