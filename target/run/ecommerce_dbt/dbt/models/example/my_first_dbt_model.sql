
  
    

  create  table "ecommerce"."staging"."my_first_dbt_model__dbt_tmp"
  
  
    as
  
  (
    

with source_data as (
    select 1 as id
    union all
    select null as id
)

select id
from source_data
where id is not null
  );
  