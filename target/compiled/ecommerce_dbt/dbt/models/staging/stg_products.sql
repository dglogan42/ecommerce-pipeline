with source as (
    select * from "ecommerce"."raw"."products"
)

select
    product_id,
    product_name,
    category,
    price::numeric(10,2) as price,
    cost::numeric(10,2) as cost
from source