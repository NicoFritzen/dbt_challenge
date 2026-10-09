select
    source_record_key,
    transaction_id,
    client_id,
    asset_ticker,
    operation,
    quantity,
    unit_price,
    transaction_date,
    gross_amount,
    signed_quantity,
    signed_amount
from {{ ref('int_transactions') }}
