-- Rank every usable description per stock code. rank 1 = the one dim_product uses.
-- Real product names in this dataset are ALL CAPS; operational notes
-- ("damaged", "check") are lower case, so upper-case wins, then the longest,
-- then alphabetical so the choice is deterministic.

with usable as (
    select stock_code, description, count(*) as times_used
    from {{ ref('stg_online_retail') }}
    where description is not null
    group by stock_code, description
)

select
    stock_code,
    description,
    times_used,
    row_number() over (
        partition by stock_code
        order by
            case when description = upper(description) then 0 else 1 end,
            length(description) desc,
            times_used desc,
            description asc
    ) as description_rank
from usable
