{{ config(tags=['integrity']) }}

select client_id, count(*) as row_count
from {{ ref('stg_clients') }}
group by client_id
having count(*) > 1
