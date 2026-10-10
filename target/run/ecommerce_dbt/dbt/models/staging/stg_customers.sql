
  create view "ecommerce"."staging"."stg_customers__dbt_tmp"
    
    
  as (
    with source as (
    select * from "ecommerce"."raw"."customers"
)

select
    customer_id,
    first_name,
    last_name,
    email,
    city,
    country,
    signup_date::date as signup_date
from source
  );