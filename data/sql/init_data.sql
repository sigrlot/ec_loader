-- SELECT
--     inhrelid::regclass AS child_table
-- FROM
--     pg_inherits
-- WHERE
--     inhparent = 'public.transaction'::regclass;
CREATE TABLE IF NOT EXISTS public.transaction_p0 PARTITION OF public.transaction FOR
VALUES IN (0);
CREATE TABLE IF NOT EXISTS public.message_p0 PARTITION OF public.message FOR
VALUES IN (0);

-- Insert records into message_type table
INSERT INTO public.message_type (
        "type",
        business_msg_type,
        "module",
        "label",
        height
    )
VALUES (
        'cosmos.bank.v1beta1.MsgSend',
        '{}',
        'bank',
        'MsgSend',
        74
    ),
    (
        'ec.dao.MsgUpdateDao',
        '{}',
        'ec dao',
        'MsgUpdateDao',
        0
    ),
    (
        'ec.dao.MsgUpdateGasFeeAccount',
        '{}',
        'ec dao',
        'MsgUpdateGasFeeAccount',
        0
    ),
    (
        'ec.staking.MsgStakeEcRequest',
        '{}',
        'ec staking',
        'MsgStakeEcRequest',
        0
    ),
    (
        'ec.staking.MsgUpdateMinSettleTpbRequest',
        '{}',
        'ec staking',
        'MsgUpdateMinSettleTpbRequest',
        0
    ),
    (
        'ec.staking.MsgWithDrawEcRequest',
        '{}',
        'ec staking',
        'MsgWithDrawEcRequest',
        0
    ),
    (
        'cosmos.staking.v1beta1.MsgCreateValidator',
        '{}',
        'staking',
        'MsgCreateValidator',
        0
    ),
    (
        'ec.staking.MsgRemoveValidatorRequest',
        '{}',
        'ec staking',
        'MsgRemoveValidatorRequest',
        0
    ),
    (
        'cosmos.bank.v1beta1.MsgMultiSend',
        '{}',
        'bank',
        'MsgMultiSend',
        0
    );
-- Insert records into module_accounts table
INSERT INTO public.module_accounts (
        address,
        "name",
        account_type,
        description,
        region_id
    )
VALUES (
        'ec1mk7pw34ypusacm29m92zshgxee3yreumfj6vme',
        'rollapp',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec1fl48vsnmsdzcv85q5d2q4z5ajdha8yu37nzfmr',
        'bonded_tokens_pool',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec14gcccn42ucahkf32nkug0t284y78hrmx3qfvl8',
        'not_bonded_stake_tokens_pool',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec1h3j5kq3efj96ga8gre6pxmp2qmfvs994e7sgqs',
        'txfees',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec136dew87j9gguzc3u8d2wp8p6wqgw5jz7p7jyjs',
        'init_allocate_pool',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec1vwr8z00ty7mqnk4dtchr9mn9j96nuh6wjk37kq',
        'dao',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec1w6qn6k7cum32mujh8rjf07yupj4qcgczu6egs6',
        'delayedack',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec1g920yuxdmqtfxg4w8a0j9sgaazfryr2cd8xckq',
        'bonded_stake_tokens_pool',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec13khtvp20yphkmc2uc43tmsngswh88al73xu2yw',
        'sequencer',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    ),
    (
        'ec1gmpxkchcdgfq995zye5efwzfw86zfa4vqaal9u',
        'stake_tokens_pool',
        '/cosmos.auth.v1beta1.ModuleAccount',
        '',
        NULL
    );
-- Insert records into validator table
INSERT INTO public."validator" (consensus_address, consensus_pubkey)
VALUES (
        'ecvalcons1e66y0rtg2gudksttfss4nlaxuz7xlndeul4j83',
        'PubKeyEd25519{FC476046453E1C29B9642B54F3DFAC316F004BABA1214B13758800BBC038F178}'
    ),
    (
        'ecvalcons1w0r2za3jga74mj357nrfdm9jn4plwdmpwu9pun',
        'ecvalconspub13szgg0gye75qnejr07c4cef2lktmhe6wy335ux3rtq0urs8g89yse0hrnj'
    );
-- Insert records into account table
INSERT INTO public.account (address)
VALUES ('ec12zguw369jyptuuahjuv7n6fkkey9ratj0q6aaj'),
    ('ec1n4mljxl7te3j4keac82uqpf720ewut8f7g28v5');
-- Insert records into validator_info table
INSERT INTO public.validator_info (
        consensus_address,
        operator_address,
        self_delegate_address,
        max_change_rate,
        max_rate,
        height
    )
VALUES (
        'ecvalcons1e66y0rtg2gudksttfss4nlaxuz7xlndeul4j83',
        'ecvaloper12zguw369jyptuuahjuv7n6fkkey9ratj5n6q63',
        'ec12zguw369jyptuuahjuv7n6fkkey9ratj0q6aaj',
        '0.010000000000000000',
        '0.200000000000000000',
        0
    ),
    (
        'ecvalcons1w0r2za3jga74mj357nrfdm9jn4plwdmpwu9pun',
        'ecvaloper1n4mljxl7te3j4keac82uqpf720ewut8f9m26th',
        'ec1n4mljxl7te3j4keac82uqpf720ewut8f7g28v5',
        '0.010000000000000000',
        '0.200000000000000000',
        0
    );