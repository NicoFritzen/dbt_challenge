select
    client_id,
    asset_ticker,
    sum(case when operation = 'BUY' then quantity else 0 end)::decimal(18, 4) as total_buy_quantity,
    sum(case when operation = 'SELL' then quantity else 0 end)::decimal(18, 4) as total_sell_quantity,
    sum(signed_quantity)::decimal(18, 4) as net_quantity,
    sum(case when operation = 'BUY' then gross_amount else 0 end)::decimal(28, 8) as gross_buy_amount,
    sum(case when operation = 'SELL' then gross_amount else 0 end)::decimal(28, 8) as gross_sell_amount,
    sum(signed_amount)::decimal(28, 8) as net_amount
from {{ ref('int_transactions') }}
group by client_id, asset_ticker
