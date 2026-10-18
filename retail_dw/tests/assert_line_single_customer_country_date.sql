-- The MIN() used in int_sales_lines is only safe if each line has ONE customer,
-- ONE country and ONE calendar date. Any line that breaks this is returned (hard failure).
-- (Customers are counted ignoring nulls, so guest lines count as 0 and pass.)
select invoice_no, stock_code, distinct_customers, distinct_countries, distinct_dates
from {{ ref('int_sales_lines') }}
where distinct_customers > 1 or distinct_countries > 1 or distinct_dates > 1
