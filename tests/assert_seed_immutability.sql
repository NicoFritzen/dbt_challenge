{{ config(tags=['integrity']) }}

with seed_counts as (
    select
        (select count(*) from {{ ref('clients') }}) as client_count,
        (select count(*) from {{ ref('transactions') }}) as transaction_count,
        (select min(client_id) from {{ ref('clients') }}) as first_client_id,
        (select max(transaction_id) from {{ ref('transactions') }}) as last_transaction_id
)
select *
from seed_counts
where client_count <> 27
   or transaction_count <> 100
   or first_client_id <> 'C1'
   or last_transaction_id <> 'T100'
