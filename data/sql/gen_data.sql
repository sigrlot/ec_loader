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
        FROM public.validator_info
        ORDER BY random()
        LIMIT 1
    ) as proposer_address,
    NOW() - (random() * interval '365 days') as "timestamp"
FROM generate_series(1, 10000) as i ON CONFLICT DO NOTHING;
-- Insert records into transaction table
DELETE FROM public.transaction;
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
        FROM public.block
        ORDER BY random()
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
FROM generate_series(1, 100000) as i ON CONFLICT DO NOTHING;
-- Insert 200,000 records into message table
DELETE FROM public.message;
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
        FROM public.transaction
        ORDER BY random()
        LIMIT 1
    ) as transaction_hash,
    (i % 10) as "index",
    (
        SELECT type
        FROM public.message_type
        ORDER BY random()
        LIMIT 1
    ) as "type",
    '{}' as value,
    (
        SELECT ARRAY(
                SELECT address
                FROM public.balance_states
                ORDER BY random()
                LIMIT (2 + (random() * 4)::int)
            )
    ) as involved_accounts_addresses,
    0 as partition_id,
    (
        SELECT height
        FROM public.block
        ORDER BY random()
        LIMIT 1
    ) as height
FROM generate_series(1, 200000) as i ON CONFLICT DO NOTHING;
DELETE FROM public.parsed_message;
-- Insert 200,000 records into parsed_message table
INSERT INTO public.parsed_message (
        height,
        tx_hash,
        msg_index,
        detail,
        msg_type,
        description
    )
SELECT (
        SELECT height
        FROM public.block
        ORDER BY random()
        LIMIT 1
    ) as height,
    (
        SELECT hash
        FROM public.transaction
        ORDER BY random()
        LIMIT 1
    ) as tx_hash,
    (i % 10) as msg_index,
    '{}' as detail,
    (
        SELECT type
        FROM public.message_type
        ORDER BY random()
        LIMIT 1
    ) as msg_type,
    'Description for message ' || i::text as description
FROM generate_series(1, 200000) as i ON CONFLICT DO NOTHING;
DELETE FROM public.fee_records;
-- Insert 100,000 records into fee_records table
INSERT INTO public.fee_records (
        created_at,
        updated_at,
        deleted_at,
        height,
        tx_hash,
        fee_payer,
        fee_amount,
        fee_denom,
        invoke_address,
        receivers,
        partition_id
    )
SELECT NOW() - (random() * interval '365 days') as created_at,
    NOW() - (random() * interval '365 days') as updated_at,
    NULL as deleted_at,
    t.height,
    t.hash as tx_hash,
    (
        SELECT address
        FROM public.balance_states
        ORDER BY random()
        LIMIT 1
    ) as fee_payer,
    (random() * 100000)::int8 as fee_amount,
    'uec' as fee_denom,
    (
        SELECT ARRAY(
                SELECT address
                FROM public.balance_states
                ORDER BY random()
                LIMIT (1 + (random() * 3)::int)
            )
    ) as invoke_address,
    NULL as receivers,
    0 as partition_id
FROM (
        SELECT hash,
            height
        FROM public.transaction
        ORDER BY random()
        LIMIT 100000
    ) t ON CONFLICT DO NOTHING;
DELETE FROM public.stake_ec_statics;
-- Insert 100,000 records into stake_ec_statics table
INSERT INTO public.stake_ec_statics (
        staker_address,
        amount,
        block_height
    )
SELECT bs.address as staker_address,
    (random() * 1000000)::int8 as amount,
    (
        SELECT height
        FROM public.block
        ORDER BY random()
        LIMIT 1
    ) as block_height
FROM (
        SELECT address
        FROM public.balance_states
        ORDER BY random()
        LIMIT 100000
    ) bs ON CONFLICT DO NOTHING;
DELETE FROM public.transfer_in_msgs;
-- Insert 400,000 records into transfer_in_msgs table
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
    (
        SELECT hash
        FROM public.transaction
        ORDER BY random()
        LIMIT 1
    ) as tx_hash,
    (
        SELECT height
        FROM public.block
        ORDER BY random()
        LIMIT 1
    ) as height,
    (i % 10) as msg_index,
    (
        SELECT type
        FROM public.message_type
        ORDER BY random()
        LIMIT 1
    ) as msg_type,
    (
        SELECT address
        FROM public.balance_states
        ORDER BY random()
        LIMIT 1
    ) as sender,
    (
        SELECT address
        FROM public.balance_states
        ORDER BY random()
        LIMIT 1
    ) as receiver,
    (
        SELECT ARRAY(
                SELECT address
                FROM public.balance_states
                ORDER BY random()
                LIMIT (1 + (random() * 2)::int)
            )
    ) as invoke_address,
    (random() * 1000000)::int::text as coins,
    '{uec}'::_text as token_types,
    (random() > 0.8)::bool as has_ibc_token,
    'tag_' || (i % 100)::text as tag
FROM generate_series(1, 400000) as i ON CONFLICT DO NOTHING;