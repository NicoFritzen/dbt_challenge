with transactions as (
    select * from {{ ref('stg_transactions') }}
),
clients as (
    select client_id from {{ ref('stg_clients') }}
),
classified as (
    select
        t.*,
        case
            when not t.is_valid then 'invalid_transaction_fields'
            when t.duplicate_rank > 1 then 'duplicate_transaction_id'
            when t.client_id is null then 'missing_client_id'
            when c.client_id is null then 'unknown_client_id'
            else null
        end as rejection_reason
    from transactions t
    left join clients c on t.client_id = c.client_id
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
    duplicate_rank,
    rejection_reason
from classified
where rejection_reason is not null
