-- One row per stock code, including non-product codes (postage, fees...),
-- which are kept and labelled instead of being thrown away.

with all_codes as (
    select distinct stock_code from {{ ref('stg_online_retail') }}
),

best_description as (
    select stock_code, description
    from {{ ref('int_product_descriptions_ranked') }}
    where description_rank = 1
),

non_product as (
    select upper(stock_code) as stock_code, description, category
    from {{ ref('non_product_stock_codes') }}
)

select
    c.stock_code::text                                              as stock_code,
    coalesce(np.description, bd.description,
             'Unknown Product - ' || c.stock_code)::text            as description,
    case when np.stock_code is not null then 'Non-product'
         else 'Product' end::text                                   as product_type,
    coalesce(np.category, 'Product')::text                          as category,
    (np.stock_code is not null)                                     as is_non_product
from all_codes c
left join best_description bd on bd.stock_code = c.stock_code
left join non_product np      on np.stock_code = c.stock_code
