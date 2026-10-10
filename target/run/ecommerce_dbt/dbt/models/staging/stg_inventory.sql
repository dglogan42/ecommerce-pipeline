
  create view "ecommerce"."staging"."stg_inventory__dbt_tmp"
    
    
  as (
    with source as (
    select * from "ecommerce"."raw"."inventory"
)

select
    product_id,
    quantity_on_hand,
    last_updated::timestamp as last_updated
from source
  );