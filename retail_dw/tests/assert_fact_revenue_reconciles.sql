-- Total revenue in the fact must equal total quantity*price in staging (no revenue lost).
select s.v as staging_revenue, f.v as fact_revenue
from (select sum(quantity * unit_price) as v from {{ ref('stg_online_retail') }}) s
cross join (select sum(revenue) as v from {{ ref('fct_sales') }}) f
where abs(s.v - f.v) > 0.01
