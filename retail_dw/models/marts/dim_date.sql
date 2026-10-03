 {{
  config(
    post_hook="DO $$ BEGIN
      ALTER TABLE {{ this }} ADD CONSTRAINT dim_date_pk UNIQUE (invoice_date);
      EXCEPTION WHEN duplicate_table THEN NULL;
    END $$;"
  )
}}

with dates as (
    select distinct
        to_timestamp(invoice_date, 'MM/DD/YYYY HH24:MI') as invoice_date
    from {{ ref('stg_online_retail') }}
    where invoice_date is not null
)

select
    invoice_date,
    invoice_date::date                as calendar_date,
    extract(year from invoice_date)   as year,
    extract(month from invoice_date)  as month,
    extract(day from invoice_date)    as day,
    extract(quarter from invoice_date) as quarter,
    to_char(invoice_date, 'Day')      as day_of_week,
    to_char(invoice_date, 'Month')    as month_name

from dates