-- Proper daily calendar (one row per day, no gaps), built with a date spine.

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('calendar_start') ~ "' as date)",
        end_date="cast('" ~ var('calendar_end') ~ "' as date)"
    ) }}
)

select
    cast(to_char(date_day, 'YYYYMMDD') as integer)    as date_key,
    cast(date_day as date)                            as calendar_date,
    cast(extract(year from date_day) as integer)      as year,
    cast(extract(quarter from date_day) as integer)   as quarter,
    cast(extract(month from date_day) as integer)     as month,
    cast(extract(day from date_day) as integer)       as day,
    cast(to_char(date_day, 'FMMonth') as text)        as month_name,
    cast(to_char(date_day, 'FMDay') as text)          as day_of_week,
    extract(isodow from date_day) in (6, 7)           as is_weekend
from spine
