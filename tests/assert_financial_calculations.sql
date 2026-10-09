{{ config(tags=['integrity']) }}

select *
from {{ ref('fact_transactions') }}
where gross_amount <> cast(quantity * unit_price as decimal(28, 8))
   or signed_quantity <> cast(case when operation = 'BUY' then quantity else -quantity end as decimal(18, 4))
   or signed_amount <> cast(case when operation = 'BUY' then gross_amount else -gross_amount end as decimal(28, 8))
