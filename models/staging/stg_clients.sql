with source_data as (
    select
        cast(client_id as varchar) as client_id,
        nullif(trim(cast(name as varchar)), '') as name,
        nullif(trim(cast(city as varchar)), '') as city,
        nullif(trim(cast(state as varchar)), '') as state,
        cast(created_at as date) as created_at
    from {{ ref('clients') }}
),
scored as (
    select
        *,
        (
            case when client_id is not null then 1 else 0 end
            + case when name is not null then 1 else 0 end
            + case when city is not null then 1 else 0 end
            + case when state is not null then 1 else 0 end
            + case when created_at is not null then 1 else 0 end
        ) as completeness_score,
        md5(concat_ws('||',
            coalesce(client_id, '<null>'),
            coalesce(name, '<null>'),
            coalesce(city, '<null>'),
            coalesce(state, '<null>'),
            coalesce(cast(created_at as varchar), '<null>')
        )) as source_record_key
    from source_data
),
ranked as (
    select
        *,
        row_number() over (
            partition by client_id
            order by completeness_score desc, created_at desc nulls last, source_record_key
        ) as deduplication_rank
    from scored
)
select
    client_id,
    name,
    city,
    state,
    created_at,
    completeness_score,
    source_record_key,
    deduplication_rank
from ranked
where client_id is not null
  and deduplication_rank = 1
