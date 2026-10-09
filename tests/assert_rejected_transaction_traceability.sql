{{ config(tags=['integrity']) }}

select a.source_record_key
from {{ ref('audit_rejected_transactions') }} a
left join {{ ref('stg_transactions') }} t
  on a.source_record_key = t.source_record_key
where t.source_record_key is null
