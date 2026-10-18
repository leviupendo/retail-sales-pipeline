{{ config(severity='warn') }}
-- Lines whose raw rows carry more than one timestamp on the same day (e.g. a minute apart).
-- fct_sales uses the earliest; the date is unaffected.
select invoice_no, stock_code, distinct_timestamps
from {{ ref('int_sales_lines') }}
where distinct_timestamps > 1
