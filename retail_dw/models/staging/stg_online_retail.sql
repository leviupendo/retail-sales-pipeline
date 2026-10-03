-- Staging model: light cleanup of raw_online_retail.
-- No business logic here yet — just renaming to snake_case and basic typing.
-- This is the single place we'd fix things if the raw source ever changes shape.

select
    "InvoiceNo"    as invoice_no,
    "StockCode"    as stock_code,
    "Description"  as description,
    "Quantity"     as quantity,
    "InvoiceDate"  as invoice_date,
    "UnitPrice"    as unit_price,
    "CustomerID"   as customer_id,
    "Country"      as country

from {{ source('raw', 'raw_online_retail') }}