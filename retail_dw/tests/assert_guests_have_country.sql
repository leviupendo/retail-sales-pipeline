-- Guest checkouts (customer_id = -1) must still carry their real country.
select invoice_no, stock_code
from {{ ref('fct_sales') }}
where customer_id = -1 and country_name in ('Unknown')
