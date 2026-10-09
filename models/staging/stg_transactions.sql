with source_data as (
    select
        cast(transaction_id as varchar) as transaction_id,
        nullif(trim(cast(client_id as varchar)), '') as client_id,
        nullif(trim(cast(asset_ticker as varchar)), '') as asset_ticker,
        upper(nullif(trim(cast(operation as varchar)), '')) as operation,
        cast(quantity as decimal(18, 4)) as quantity,
        cast(unit_price as decimal(18, 4)) as unit_price,
        cast(transaction_date as date) as transaction_date
    from {{ ref('transactions') }}
),
ranked as (
    select
        *,
        md5(concat_ws('||',
            coalesce(transaction_id, '<null>'),
            coalesce(client_id, '<null>'),
            coalesce(asset_ticker, '<null>'),
            coalesce(operation, '<null>'),
            coalesce(cast(quantity as varchar), '<null>'),
            coalesce(cast(unit_price as varchar), '<null>'),
            coalesce(cast(transaction_date as varchar), '<null>')
        )) as source_record_key,
        row_number() over (
            partition by transaction_id
            order by transaction_date, client_id, asset_ticker, operation,
                     quantity, unit_price
        ) as duplicate_rank
    from source_data
)
select
    *,
    transaction_id is not null
        and client_id is not null
        and asset_ticker is not null
        and operation in ('BUY', 'SELL')
        and quantity is not null
        and quantity > 0
        and unit_price is not null
        and unit_price > 0
        and transaction_date is not null as is_valid
from ranked
