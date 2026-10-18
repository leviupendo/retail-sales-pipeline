{{ config(severity='warn') }}
-- Negative quantity on a non-'C' invoice = stock adjustment (damaged, lost...), not a customer return.
select invoice_no, stock_code, quantity
from {{ ref('fct_sales') }}
where quantity < 0 and not is_cancellation
