-- One country per real customer: the country on their most recent invoice
-- (ties broken alphabetically so the result never changes between runs).

select customer_id, country
from (
    select
        customer_id,
        country,
        row_number() over (
            partition by customer_id
            order by invoice_ts desc, country asc
        ) as rn
    from {{ ref('stg_online_retail') }}
    where customer_id is not null
) ranked
where rn = 1
