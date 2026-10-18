-- One row per invoice + product line (the fact grain).
--
-- ASSUMPTION (documented, not hidden): when the same invoice_no + stock_code
-- appears on several raw rows, they are separate scans of the same item
-- (e.g. 20 rows of quantity 1), so quantities are SUMMED and nothing is dropped.
-- Revenue is sum(quantity * unit_price), so it stays correct even if prices differ.
-- `source_row_count` records how many raw rows were folded into each line, and
-- singular tests check that price / customer / country / date are consistent.

select
    invoice_no,
    stock_code,
    min(customer_id)                      as customer_id,
    min(country)                          as country,
    min(invoice_ts)                       as invoice_ts,
    sum(quantity)                         as quantity,
    min(unit_price)                       as unit_price,
    max(unit_price)                       as max_unit_price,
    sum(quantity * unit_price)            as revenue,
    bool_or(is_cancellation)              as is_cancellation,
    count(*)                              as source_row_count,
    count(distinct customer_id)           as distinct_customers,
    count(distinct country)               as distinct_countries,
    count(distinct invoice_ts)            as distinct_timestamps,
    count(distinct cast(invoice_ts as date)) as distinct_dates

from {{ ref('stg_online_retail') }}
group by invoice_no, stock_code
