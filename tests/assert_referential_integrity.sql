{{ config(tags=['integrity']) }}

select f.client_id
from {{ ref('fact_transactions') }} f
left join {{ ref('dim_clients') }} d on f.client_id = d.client_id
where d.client_id is null
