-- Insert records into balance_states table
DELETE FROM public.balance_states;
INSERT INTO public.balance_states (
        address,
        coins,
        uec_amount,
        update_at_height,
        token_types,
        region_id,
        account_types
    )
SELECT 'ec1' || substr(md5(random()::text || i::text), 1, 28) || lpad(i::text, 10, '0') as address,
    ARRAY [ROW('uec', (random() * 10000000000)::int8::text)::public.big_int_coin] as coins,
    (random() * 10000000000)::int8 as uec_amount,
    (random() * 100000)::int8 as update_at_height,
    '{uec}'::_text as token_types,
    NULL as region_id,
    (random() * 3)::int8 as account_types
FROM generate_series(1, 10000) as i ON CONFLICT DO NOTHING;
-- Insert records into block table
DELETE FROM public.block;
WITH counter AS (
    select count(*) as n
    from public.validator_info
)
INSERT INTO public.block (
        height,
        hash,
        num_txs,
        total_gas,
        proposer_address,
        "timestamp"
    )
SELECT i as height,
    encode(sha256(('block_' || i::text)::bytea), 'hex') as hash,
    (random() * 20)::int4 as num_txs,
    (random() * 10000000)::int8 as total_gas,
    (
        SELECT consensus_address
        FROM public.validator_info OFFSET i % (
                select n
                from counter
            )
        LIMIT 1
    ) as proposer_address,
    NOW() - (random() * interval '365 days') as "timestamp"
FROM generate_series(1, 10000) as i ON CONFLICT DO NOTHING;
-- Insert records into transaction table
DELETE FROM public.transaction;
WITH block_count AS (
    SELECT count(*) AS n
    FROM public.block
)
INSERT INTO public.transaction (
        hash,
        height,
        success,
        messages,
        memo,
        signatures,
        signer_infos,
        fee,
        gas_wanted,
        gas_used,
        raw_log,
        logs,
        partition_id
    )
SELECT encode(sha256(('tx_' || i::text)::bytea), 'hex') as hash,
    (
        SELECT height
        FROM public.block OFFSET I % (
                SELECT n
                FROM block_count
            )
        LIMIT 1
    ) as height,
    (random() > 0.1)::bool as success,
    '[]'::json as messages,
    'memo_' || substr(md5(random()::text), 1, 8) as memo,
    -- ARRAY [
    --     (
    --         SELECT address
    --         FROM public.balance_states
    --         ORDER BY random()
    --         LIMIT 1
    --     )
    -- ] as signatures,
    '{}'::text [] as signatures,
    '[]'::jsonb as signer_infos,
    '{}'::jsonb as fee,
    (random() * 1000000)::int8 as gas_wanted,
    (random() * 800000)::int8 as gas_used,
    'raw_log_' || i::text as raw_log,
    NULL as logs,
    0 as partition_id
FROM generate_series(1, 10000) as i ON CONFLICT DO NOTHING;
-- Insert 200,000 records into message table
DELETE FROM public.message;
WITH tx_count AS (
    SELECT count(*) AS n
    FROM public."transaction"
),
msg_type_count AS (
    SELECT count(*) AS n
    FROM public.message_type
),
address_count AS (
    SELECT count(*) AS n
    FROM public.balance_states
)
INSERT INTO public.message (
        transaction_hash,
        "index",
        "type",
        value,
        involved_accounts_addresses,
        partition_id,
        height
    )
SELECT (
        SELECT hash
        FROM public.transaction OFFSET i % (
                SELECT n
                FROM tx_count
            )
        LIMIT 1
    ) AS transaction_hash,
    (i % 2) AS "index",
    (
        SELECT type
        FROM public.message_type OFFSET i % (
                SELECT n
                FROM msg_type_count
            )
        LIMIT 1
    ) AS "type",
    '{}' AS value,
    (
        SELECT ARRAY(
                SELECT address
                FROM public.balance_states OFFSET i % (
                        SELECT n
                        FROM address_count
                    )
                LIMIT (2 + (random() * 4)::int)
            )
    ) AS involved_accounts_addresses,
    0 AS partition_id,
    (
        SELECT height
        FROM public.transaction OFFSET i % (
                SELECT n
                FROM tx_count
            )
        LIMIT 1
    ) AS height
FROM generate_series(1, 2000) AS i ON CONFLICT DO NOTHING;
-- Insert 200,000 records into parsed_message table
DELETE FROM public.parsed_message;
WITH message_count AS (
    SELECT count(*) AS n
    FROM public.message
)
INSERT INTO public.parsed_message (
        height,
        tx_hash,
        msg_index,
        detail,
        msg_type,
        description
    )
SELECT m.height,
    m.transaction_hash as tx_hash,
    m."index" as msg_index,
    '{}' as detail,
    m."type" as msg_type,
    'Description for message ' || i::text as description
FROM generate_series(1, 200000) as i
    CROSS JOIN LATERAL (
        SELECT height,
            transaction_hash,
            "index",
            "type"
        FROM public.message OFFSET i % (
                SELECT n
                FROM message_count
            )
        LIMIT 1
    ) m ON CONFLICT DO NOTHING;
-- Insert records into transfer_in_msgs table
DELETE FROM public.transfer_in_msgs;
WITH message_count AS (
    SELECT count(*) AS n
    FROM public.message
)
INSERT INTO public.transfer_in_msgs (
        created_at,
        updated_at,
        deleted_at,
        tx_hash,
        height,
        msg_index,
        msg_type,
        sender,
        receiver,
        invoke_address,
        coins,
        token_types,
        has_ibc_token,
        tag
    )
SELECT NOW() - (random() * interval '365 days') as created_at,
    NOW() - (random() * interval '365 days') as updated_at,
    NULL as deleted_at,
    m.transaction_hash as tx_hash,
    m.height,
    m."index" as msg_index,
    m."type" as msg_type,
    (m.involved_accounts_addresses) [1] as sender,
    (m.involved_accounts_addresses) [2] as receiver,
    m.involved_accounts_addresses as invoke_address,
    (random() * 100000000)::int::text as coins,
    '{uec}'::_text as token_types,
    (m."index" % 5 = 0)::bool as has_ibc_token,
    'tag_' || (m."index" % 100)::text as tag
FROM generate_series(1, 4000) as i
    CROSS JOIN LATERAL (
        SELECT transaction_hash,
            height,
            "index",
            "type",
            involved_accounts_addresses
        FROM public.message OFFSET i % (
                SELECT n
                FROM message_count
            )
        LIMIT 1
    ) m ON CONFLICT DO NOTHING;