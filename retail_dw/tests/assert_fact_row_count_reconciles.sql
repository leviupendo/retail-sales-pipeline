-- Every raw row must be accounted for in the fact: sum(source_row_count) = staging rows.
select s.n as staging_rows, f.n as fact_rows
from (select count(*) as n from {{ ref('stg_online_retail') }}) s
cross join (select sum(source_row_count) as n from {{ ref('fct_sales') }}) f
where s.n <> f.n
