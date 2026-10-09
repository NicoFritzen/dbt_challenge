{{ config(tags=['integrity']) }}

with expected as (
    select distinct client_id
    from {{ ref('stg_clients') }}
),
actual as (
    select client_id
    from {{ ref('dim_clients') }}
)
select e.client_id
from expected e
left join actual a on e.client_id = a.client_id
where a.client_id is null
