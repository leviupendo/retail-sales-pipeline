{{
  config(
    post_hook="DO $$ BEGIN
      ALTER TABLE {{ this }} ADD CONSTRAINT dim_product_pk UNIQUE (stock_code);
      EXCEPTION WHEN OTHERS THEN NULL;
    END $$;"
  )
}}with known_products as (
    select
        stock_code,
        description
    from (
        select
            stock_code,
            description,
            row_number() over (
                partition by stock_code
                order by
                    case when description = upper(description) then 0 else 1 end asc,
                    length(description) desc
            ) as rn
        from {{ ref('stg_online_retail') }}
        where stock_code is not null
          and stock_code not in ('POST', 'M', 'm', 'DOT')
          and description is not null
          and description != ''
    ) ranked
    where rn = 1
),

missing_products as (
    -- any stock_code present in staging but with no usable description at all
    select distinct
        stock_code,
        'Unknown Product - ' || stock_code as description
    from {{ ref('stg_online_retail') }}
    where stock_code is not null
      and stock_code not in ('POST', 'M', 'm', 'DOT')
      and stock_code not in (select stock_code from known_products)
)

select * from known_products
union all
select * from missing_products