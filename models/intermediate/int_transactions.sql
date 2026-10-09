with transactions as (
    select *
    from {{ ref('stg_transactions') }}
    where is_valid
      and duplicate_rank = 1
),
clients as (
    select client_id
    from {{ ref('stg_clients') }}
),
related as (
    select
        t.*
    from transactions t
    inner join clients c on t.client_id = c.client_id
)
select
    source_record_key,
    transaction_id,
    client_id,
    asset_ticker,
    operation,
    quantity,
    unit_price,
    transaction_date,
    cast(quantity * unit_price as decimal(28, 8)) as gross_amount,
    cast(case when operation = 'BUY' then quantity else -quantity end as decimal(18, 4)) as signed_quantity,
    cast(case when operation = 'BUY' then quantity * unit_price else -(quantity * unit_price) end as decimal(28, 8)) as signed_amount
from related
