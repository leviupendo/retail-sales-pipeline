-- A cancellation invoice ('C' prefix) should never add stock.
select invoice_no, stock_code, quantity
from {{ ref('fct_sales') }}
where is_cancellation and quantity > 0
