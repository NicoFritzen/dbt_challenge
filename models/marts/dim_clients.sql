select
    client_id,
    name,
    city,
    state,
    created_at,
    completeness_score,
    source_record_key
from {{ ref('stg_clients') }}
