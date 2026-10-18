-- One row per country that appears on any invoice (guests included).

select distinct country::text as country_name
from {{ ref('stg_online_retail') }}
