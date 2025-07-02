TRUNCATE TABLE public.balance_states CASCADE;
TRUNCATE TABLE public.block CASCADE;
TRUNCATE TABLE public."transaction" CASCADE;
TRUNCATE TABLE public.message CASCADE;
TRUNCATE TABLE public.parsed_message CASCADE;
TRUNCATE TABLE public.fee_records CASCADE;
TRUNCATE TABLE public.stake_ec_statics CASCADE;
TRUNCATE TABLE public.transfer_in_msgs CASCADE;
-- Insert records into balance_states table
DELETE FROM public.balance_states;
DO $$
DECLARE batch_size INTEGER := 10000;
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
n INTEGER;
BEGIN
SELECT count(*) INTO n
FROM public.validator_info;
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
    (
        SELECT consensus_address
        FROM public.validator_info OFFSET (i + j -1) % n
        LIMIT 1
    ) as proposer_address,
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
n INTEGER;
BEGIN
SELECT count(*) INTO n
FROM public.block;
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
    (
        SELECT height
        FROM public.block OFFSET ((i + j -1) % n)
        LIMIT 1
    ) as height,
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
n_tx INTEGER;
n_type INTEGER;
n_addr INTEGER;
BEGIN
SELECT count(*) INTO n_tx
FROM public.transaction;
SELECT count(*) INTO n_type
FROM public.message_type;
SELECT count(*) INTO n_addr
FROM public.balance_states;
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
SELECT (
        SELECT hash
        FROM public.transaction OFFSET ((i + j -1) % n_tx)
        LIMIT 1
    ) AS transaction_hash,
    ((i + j -1) % 2) AS "index",
    (
        SELECT type
        FROM public.message_type OFFSET ((i + j -1) % n_type)
        LIMIT 1
    ) AS "type",
    '{}' AS value,
    (
        SELECT ARRAY(
                SELECT address
                FROM public.balance_states OFFSET ((i + j -1) % n_addr)
                LIMIT (2 + (random() * 4)::int)
            )
    ) AS involved_accounts_addresses,
    0 AS partition_id,
    (
        SELECT height
        FROM public.transaction OFFSET ((i + j -1) % n_tx)
        LIMIT 1
    ) AS height
FROM generate_series(1, LEAST(batch_size, total - i + 1)) AS j ON CONFLICT DO NOTHING;
RAISE NOTICE 'message: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;
-- Insert 200,000 records into parsed_message table
DELETE FROM public.parsed_message;
DO $$
DECLARE batch_size INTEGER := 10000;
total INTEGER := 2000000;
i INTEGER := 1;
n INTEGER;
BEGIN
SELECT count(*) INTO n
FROM public.message;
WHILE i <= total LOOP
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
    'Description for message ' || (i + j -1)::text as description
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j
    CROSS JOIN LATERAL (
        SELECT height,
            transaction_hash,
            "index",
            "type"
        FROM public.message OFFSET ((i + j -1) % n)
        LIMIT 1
    ) m ON CONFLICT DO NOTHING;
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
n_tx INTEGER;
BEGIN
SELECT count(*) INTO n_tx
FROM public.transaction;
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
    (
        SELECT height
        FROM public.transaction OFFSET ((i + j -1) % n_tx)
        LIMIT 1
    ) as height,
    (
        SELECT hash
        FROM public.transaction OFFSET ((i + j -1) % n_tx)
        LIMIT 1
    ) as tx_hash,
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
n_addr INTEGER;
n_block INTEGER;
BEGIN
SELECT count(*) INTO n_addr
FROM public.balance_states;
SELECT count(*) INTO n_block
FROM public.block;
WHILE i <= total LOOP
INSERT INTO public.stake_ec_statics (
        staker_address,
        amount,
        block_height
    )
SELECT (
        SELECT address
        FROM public.balance_states OFFSET ((i + j -1) % n_addr)
        LIMIT 1
    ) as staker_address,
    (random() * 1000000)::int8 as amount,
    (
        SELECT height
        FROM public.block OFFSET ((i + j -1) % n_block)
        LIMIT 1
    ) as block_height
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
n INTEGER;
BEGIN
SELECT count(*) INTO n
FROM public.message;
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
FROM generate_series(1, LEAST(batch_size, total - i + 1)) as j
    CROSS JOIN LATERAL (
        SELECT transaction_hash,
            height,
            "index",
            "type",
            involved_accounts_addresses
        FROM public.message OFFSET ((i + j -1) % n)
        LIMIT 1
    ) m ON CONFLICT DO NOTHING;
RAISE NOTICE 'transfer_in_msgs: Inserted % rows at %',
LEAST(i + batch_size - 1, total),
clock_timestamp();
i := i + batch_size;
END LOOP;
END $$;