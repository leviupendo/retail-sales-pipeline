{{ config(severity='warn') }}
-- Lines whose raw rows carry different unit prices (unit_price shows the lowest).
-- Revenue is still exact; this just tells you where the single unit_price is a simplification.
select invoice_no, stock_code, unit_price, max_unit_price
from {{ ref('int_sales_lines') }}
where unit_price <> max_unit_price
