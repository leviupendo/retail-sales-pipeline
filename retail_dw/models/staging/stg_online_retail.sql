-- Staging: rename, type and trim. No rows are removed here.
-- Everything is parsed exactly once so downstream models can rely on real types.

select
    trim("InvoiceNo")                                          as invoice_no,
    upper(trim("StockCode"))                                   as stock_code,
    nullif(trim("Description"), '')                            as description,
    cast("Quantity" as integer)                                as quantity,
    to_timestamp(trim("InvoiceDate"), 'MM/DD/YYYY HH24:MI')    as invoice_ts,
    cast("UnitPrice" as numeric(12, 4))                        as unit_price,
    cast(cast(nullif(trim("CustomerID"), '') as numeric) as integer) as customer_id,
    trim("Country")                                            as country,
    trim("InvoiceNo") like 'C%'                                as is_cancellation

from {{ source('online_retail', 'raw_online_retail') }}
