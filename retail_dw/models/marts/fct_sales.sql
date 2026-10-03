with staging as (
    select
        invoice_no,
        stock_code,
        customer_id,
        to_timestamp(invoice_date, 'MM/DD/YYYY HH24:MI') as invoice_date,
        quantity,
        unit_price
    from {{ ref('stg_online_retail') }}
)

select
    invoice_no,
    stock_code,
    -- customer_id and invoice_date are identical across duplicate rows
    -- for the same invoice_no + stock_code, so MIN() just picks the one value
    coalesce(min(customer_id), -1) as customer_id,
    min(invoice_date)  as invoice_date,
    sum(quantity)               as quantity,
    min(unit_price)              as unit_price,
    sum(quantity * unit_price)  as revenue,
    case when sum(quantity) < 0 then true else false end as is_return

from staging
where stock_code not in ('POST', 'M', 'm', 'DOT')
group by invoice_no, stock_code