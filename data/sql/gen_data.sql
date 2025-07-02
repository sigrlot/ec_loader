TRUNCATE TABLE public.balance_states CASCADE;
TRUNCATE TABLE public.block CASCADE;
TRUNCATE TABLE public."transaction" CASCADE;
TRUNCATE TABLE public.message CASCADE;
TRUNCATE TABLE public.parsed_message CASCADE;
TRUNCATE TABLE public.fee_records CASCADE;
TRUNCATE TABLE public.stake_ec_statics CASCADE;
TRUNCATE TABLE public.transfer_in_msgs CASCADE;
-- 可选：
SET LOCAL synchronous_commit TO OFF;
-- Insert records into balance_states table
DELETE FROM public.balance_states;
DO $$
DECLARE batch_size INTEGER := 20000;
total INTEGER := 500000;
i INTEGER := 1;
BEGIN WHILE i <= total LOOP
INSERT INTO public.balance_states (
        address,
        coins,
        uec_amount,
        update_at_height,
        token_types,
        region_id,
        account_types
    )
SELECT 'ec1' || substr(md5(random()::text || (i + j -1)::text), 1, 28) || lpad((i + j -1)::text, 10, '0') as address,
    ARRAY [ROW('uec', (random() * 10000000000)::int8::text)::public.big_int_coin] as coins,
    (random() * 10000000000)::int8 as uec_amount,
    (random() * 100000)::int8 as update_at_height,
    '{uec}'::_text as token_types,
    NULL as region_id,
    (random() * 3)::int8 as account_types
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'balance_states: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
SELECT count(*)
FROM public.balance_states;
-- Insert records into block table
DELETE FROM public.block;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 1000000;
i INTEGER := 1;
arr_validator text [];
n INTEGER;
SELECT array_agg(consensus_address) INTO arr_validator
FROM public.validator_info;
n := array_length(arr_validator, 1);
WHILE i <= total LOOP
INSERT INTO public.block (
        height,
        hash,
        num_txs,
        total_gas,
        proposer_address,
        "timestamp"
    )
SELECT (i + j -1) as height,
    encode(
        sha256(('block_' || (i + j -1)::text)::bytea),
        'hex'
    ) as hash,
    (random() * 20)::int4 as num_txs,
    (random() * 10000000)::int8 as total_gas,
    arr_validator [((i + j -1) % n) + 1] as proposer_address,
    NOW() - (random() * interval '365 days') as "timestamp"
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'block: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert records into transaction table
DELETE FROM public.transaction;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 1000000;
i INTEGER := 1;
arr_block int8 [];
n INTEGER;
SELECT array_agg(height) INTO arr_block
FROM public.block
ORDER BY height;
n := array_length(arr_block, 1);
WHILE i <= total LOOP
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
SELECT encode(
        sha256(('tx_' || (i + j -1)::text)::bytea),
        'hex'
    ) as hash,
    arr_block [((i + j -1) % n) + 1] as height,
    (random() > 0.1)::bool as success,
    '[]'::json as messages,
    'memo_' || substr(md5(random()::text), 1, 8) as memo,
    '{}'::text [] as signatures,
    '[]'::jsonb as signer_infos,
    '{}'::jsonb as fee,
    (random() * 1000000)::int8 as gas_wanted,
    (random() * 800000)::int8 as gas_used,
    'raw_log_' || (i + j -1)::text as raw_log,
    NULL as logs,
    0 as partition_id
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'transaction: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert 200,000 records into message table
DELETE FROM public.message;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 2000000;
i INTEGER := 1;
arr_tx text [];
arr_type text [];
arr_addr text [];
n_tx INTEGER;
n_type INTEGER;
n_addr INTEGER;
SELECT array_agg(hash) INTO arr_tx
FROM public.transaction
ORDER BY hash;
SELECT array_agg(type) INTO arr_type
FROM public.message_type
ORDER BY type;
SELECT array_agg(address) INTO arr_addr
FROM public.balance_states
ORDER BY address;
n_tx := array_length(arr_tx, 1);
n_type := array_length(arr_type, 1);
n_addr := array_length(arr_addr, 1);
WHILE i <= total LOOP
INSERT INTO public.message (
        transaction_hash,
        "index",
        "type",
        value,
        involved_accounts_addresses,
        partition_id,
        height
    )
SELECT arr_tx [((i + j -1) % n_tx) + 1] AS transaction_hash,
    ((i + j -1) % 2) AS "index",
    arr_type [((i + j -1) % n_type) + 1] AS "type",
    '{}' AS value,
    ARRAY(
        SELECT arr_addr [((i + j -1 + k - 1) % n_addr) + 1]
        FROM generate_series(1, 2 + (random() * 4)::int) AS k
    ) AS involved_accounts_addresses,
    0 AS partition_id,
    arr_block [((i + j -1) % n) + 1] AS height
FROM generate_series(1, LEAST(batch_size, total - i + 1)) AS j ON CONFLICT DO NOTHING;
RAISE NOTICE 'message: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert records into parsed_message table
DELETE FROM public.parsed_message;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 2000000;
i INTEGER := 1;
arr_msg_height int8 [];
arr_msg_tx text [];
arr_msg_index int [];
arr_msg_type text [];
n INTEGER;
-- 合并为一次查询
SELECT array_agg(
        height
        ORDER BY height
    ),
    array_agg(
        transaction_hash
        ORDER BY height
    ),
    array_agg(
        "index"
        ORDER BY height
    ),
    array_agg(
        "type"
        ORDER BY height
    ) INTO arr_msg_height,
    arr_msg_tx,
    arr_msg_index,
    arr_msg_type
FROM public.message;
n := array_length(arr_msg_height, 1);
WHILE i <= total LOOP
INSERT INTO public.parsed_message (
        height,
        tx_hash,
        msg_index,
        detail,
        msg_type,
        description
    )
SELECT arr_msg_height [((i + j -1) % n) + 1],
    arr_msg_tx [((i + j -1) % n) + 1],
    arr_msg_index [((i + j -1) % n) + 1],
    '{}' as detail,
    arr_msg_type [((i + j -1) % n) + 1],
    'Description for message ' || (i + j -1)::text as description
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'parsed_message: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert records into fee_records table
DELETE FROM public.fee_records;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 100000;
i INTEGER := 1;
arr_tx_height int8 [];
arr_tx_hash text [];
n_tx INTEGER;
SELECT array_agg(height) INTO arr_tx_height
FROM public.transaction
ORDER BY height;
SELECT array_agg(hash) INTO arr_tx_hash
FROM public.transaction
ORDER BY height;
n_tx := array_length(arr_tx_height, 1);
WHILE i <= total LOOP
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
    arr_tx_height [((i + j -1) % n_tx) + 1] as height,
    arr_tx_hash [((i + j -1) % n_tx) + 1] as tx_hash,
    NULL as fee_payer,
    (random() * 100000)::int8 as fee_amount,
    'uec' as fee_denom,
    NULL as invoke_address,
    NULL as receivers,
    0 as partition_id
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'fee_records: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert records into stake_ec_statics table
DELETE FROM public.stake_ec_statics;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 100000;
i INTEGER := 1;
arr_addr text [];
arr_block int8 [];
n_addr INTEGER;
n_block INTEGER;
SELECT array_agg(address) INTO arr_addr
FROM public.balance_states
ORDER BY address;
SELECT array_agg(height) INTO arr_block
FROM public.block
ORDER BY height;
n_addr := array_length(arr_addr, 1);
n_block := array_length(arr_block, 1);
WHILE i <= total LOOP
INSERT INTO public.stake_ec_statics (
        staker_address,
        amount,
        block_height
    )
SELECT arr_addr [((i + j -1) % n_addr) + 1] as staker_address,
    (random() * 1000000)::int8 as amount,
    arr_block [((i + j -1) % n_block) + 1] as block_height
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'stake_ec_statics: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert records into transfer_in_msgs table
DELETE FROM public.transfer_in_msgs;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 4000000;
i INTEGER := 1;
arr_msg_tx text [];
arr_msg_height int8 [];
arr_msg_index int [];
arr_msg_type text [];
arr_msg_addr text [] [];
n INTEGER;
-- 合并为一次查询
SELECT array_agg(
        transaction_hash
        ORDER BY height
    ),
    array_agg(
        height
        ORDER BY height
    ),
    array_agg(
        "index"
        ORDER BY height
    ),
    array_agg(
        "type"
        ORDER BY height
    ),
    array_agg(
        involved_accounts_addresses
        ORDER BY height
    ) INTO arr_msg_tx,
    arr_msg_height,
    arr_msg_index,
    arr_msg_type,
    arr_msg_addr
FROM public.message;
n := array_length(arr_msg_tx, 1);
WHILE i <= total LOOP
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
    arr_msg_tx [((i + j -1) % n) + 1] as tx_hash,
    arr_msg_height [((i + j -1) % n) + 1] as height,
    arr_msg_index [((i + j -1) % n) + 1] as msg_index,
    arr_msg_type [((i + j -1) % n) + 1] as msg_type,
    (arr_msg_addr [((i + j -1) % n) + 1]) [1] as sender,
    (arr_msg_addr [((i + j -1) % n) + 1]) [2] as receiver,
    arr_msg_addr [((i + j -1) % n) + 1] as invoke_address,
    (random() * 100000000)::int::text as coins,
    '{uec}'::_text as token_types,
    (arr_msg_index [((i + j -1) % n) + 1] % 5 = 0)::bool as has_ibc_token,
    'tag_' || (arr_msg_index [((i + j -1) % n) + 1] % 100)::text as tag
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j ON CONFLICT DO NOTHING;
RAISE NOTICE 'transfer_in_msgs: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;