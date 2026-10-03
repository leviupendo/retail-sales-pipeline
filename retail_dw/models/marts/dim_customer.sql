{{
  config(
    post_hook="DO $$ BEGIN
      ALTER TABLE {{ this }} ADD CONSTRAINT dim_customer_pk UNIQUE (customer_id);
      EXCEPTION WHEN duplicate_table THEN NULL;
    END $$;"
  )
}}with known_customers as (

    select
        customer_id,
        country
    from (
        select
            customer_id,
            country,
            row_number() over (
                partition by customer_id
                order by country asc
            ) as rn
        from {{ ref('stg_online_retail') }}
        where customer_id is not null
    ) ranked
    where rn = 1

)

select * from known_customers

union all

select
    -1              as customer_id,
    'Unknown'       as country