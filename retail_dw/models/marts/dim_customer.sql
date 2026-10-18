-- One row per customer, plus an explicit -1 "Guest / Unknown" row so guest
-- checkouts stay visible. The guest's real country lives on fct_sales.

select customer_id::integer as customer_id, country::text as country
from {{ ref('int_customer_country') }}

union all

select -1 as customer_id, 'Unknown' as country
