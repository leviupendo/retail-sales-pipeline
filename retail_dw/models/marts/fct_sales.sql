-- Grain: one row per invoice_no + stock_code.
-- Nothing is excluded: postage, fees and adjustments stay and are flagged
-- (is_non_product) so dashboards can filter them; guests have customer_id = -1.

select
    l.invoice_no::text                                     as invoice_no,
    l.stock_code::text                                     as stock_code,
    coalesce(l.customer_id, -1)::integer                   as customer_id,
    l.country::text                                        as country_name,
    cast(to_char(l.invoice_ts, 'YYYYMMDD') as integer)     as date_key,
    l.invoice_ts::timestamp                                as invoice_ts,
    l.quantity::integer                                    as quantity,
    l.unit_price::numeric(12, 4)                           as unit_price,
    l.revenue::numeric(14, 4)                              as revenue,
    l.is_cancellation                                      as is_cancellation,
    (np.stock_code is not null)                            as is_non_product,
    l.source_row_count::integer                            as source_row_count
from {{ ref('int_sales_lines') }} l
left join {{ ref('non_product_stock_codes') }} np
       on np.stock_code = l.stock_code
