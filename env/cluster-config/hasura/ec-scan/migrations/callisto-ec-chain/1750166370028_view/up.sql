-- public.raw_block_logs source

CREATE OR REPLACE VIEW public.raw_block_log_view
AS SELECT rb.height,
	convert_from(rb.raw_data,'UTF8')::json as block,
	convert_from(rb.raw_block_result,'UTF8')::json as log
   FROM raw_blocks rb ;

CREATE OR REPLACE VIEW public.block_gas_fee
AS 
SELECT fr.height,fr.fee_denom,sum(fr.fee_amount) as total_fee
   FROM fee_records fr
   GROUP BY 
    (fr.height,fr.fee_denom);

-- public.validator_weight_view source


create or replace
view public.validator_weight_view
as
select
    vi.consensus_address as validator_address ,
    coalesce(vvp.voting_power::numeric / 1000000000000000000.0,
             0) as weight
from
    validator_info vi
        left join validator_voting_power vvp on
        vvp.validator_address = vi.consensus_address ;

-- public.transfer_combine_view source


CREATE OR REPLACE VIEW public.transfer_combine_view
AS SELECT tim.msg_type AS type,
    tim.height,
    tim.tx_hash,
    tim.sender AS from_address,
    tim.receiver AS to_address,
    tim.coins AS amount,
    tim.invoke_address,
    tim.msg_index,
    tim.token_types,
    tim.has_ibc_token,
    tim.tag as tag
   FROM transfer_in_msgs tim
UNION ALL
 SELECT
    'transfer_in_abci'::text AS type,
    tia.height,
    NULL::text AS tx_hash,
    tia.sender AS from_address,
    tia.receiver AS to_address,
    tia.coins AS amount,
    tia.invoke_address,
    NULL::integer AS msg_index,
    tia.token_types,
    tia.has_ibc_token,
    tia.tag
   FROM transfer_in_abci tia;


CREATE OR REPLACE VIEW public.module_account_transfers
AS WITH module_addresses AS (
    SELECT ARRAY_AGG(address) AS addresses
    FROM module_accounts
)
SELECT view_t.type,
    view_t.height,
    view_t.tx_hash,
    view_t.from_address,
    view_t.to_address,
    view_t.amount,
    view_t.invoke_address,
    view_t.msg_index,
    view_t.token_types,
    view_t.has_ibc_token,
    view_t.tag as tag
FROM transfer_combine_view view_t, module_addresses ma
WHERE view_t.invoke_address && ma.addresses;

-- public.amount_in_tx_view source

CREATE OR REPLACE VIEW public.amount_in_tx_view
AS SELECT transfer_in_msgs.tx_hash,
    sum(NULLIF(substring(transfer_in_msgs.coins, '([0-9]+)uec.*'::text), '0')::numeric) AS total_coins
   FROM transfer_in_msgs
  GROUP BY transfer_in_msgs.tx_hash;



-- public.transfer_in_msgs_split_uec_coin_view source

CREATE OR REPLACE VIEW public.transfer_in_msgs_split_uec_coin_view
AS SELECT id,
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
    tag,
    NULLIF("substring"(coins, '([0-9]+)uec.*'::text), '0'::text)::numeric AS uec_coin_amount,
    'uec'::text AS coin_denom
   FROM transfer_in_msgs;



-- DROP FUNCTION public.format_big_int_coin(_big_int_coin);

CREATE OR REPLACE FUNCTION public.format_big_int_coin(big_int_coin[])
 RETURNS text[]
 LANGUAGE plpgsql
AS $function$
DECLARE
    result text[];
    coin big_int_coin;
BEGIN
    FOREACH coin IN ARRAY $1 LOOP
        result := array_append(result, coin.amount::text || coin.denom);
    END LOOP;
    RETURN result;
END;
$function$
;

-- public.asset_change_logs_view source
CREATE OR REPLACE VIEW public.asset_change_logs_view
AS SELECT address,
    tx_hash,
    height,
    trigger_by,
    format_big_int_coin(before_change) AS before_change,
    format_big_int_coin(after_change) AS after_change,
    format_big_int_coin(change) AS change,
    transfer_seq_in_block
   FROM asset_change_logs;


-- public.raw_block_log_view source

CREATE OR REPLACE VIEW public.raw_block_log_view
AS SELECT height,
    convert_from(raw_data, 'UTF8'::name)::json AS block,
    convert_from(raw_block_result, 'UTF8'::name)::json AS log
   FROM raw_blocks rb;


-- public.liquidity_info_view source

CREATE OR REPLACE VIEW public.liquidity_info_view
AS WITH module_address AS (
         SELECT ma.name,
            GREATEST(COALESCE(bs.uec_amount, 0::numeric), 0::numeric) AS uec_amount
           FROM module_accounts ma
             LEFT JOIN balance_states bs ON bs.address = ma.address
          WHERE ma.name = 'gov'::text OR ma.name = 'reward_token_pool'::text
        ), module_address_sum AS (
         SELECT 'module_address_sum'::text AS name,
            GREATEST(COALESCE(sum(module_address.uec_amount), 0::numeric), 0::numeric) AS uec_amount
           FROM module_address
        ), total_stake AS (
         SELECT 'total_stake'::text AS name,
            GREATEST(COALESCE(sum(stake_ec_statics.amount), 0::numeric), 0::numeric) AS uec_amount
           FROM stake_ec_statics
        ), total_liquidity AS (
         SELECT 'total_liquidity'::text AS name,
            GREATEST((1000000000::bigint * 100000000)::numeric - ts.uec_amount - mas.uec_amount, 0::numeric) AS uec_amount
           FROM total_stake ts,
            module_address_sum mas
        )
 SELECT module_address.name,
    module_address.uec_amount
   FROM module_address
UNION ALL
 SELECT total_stake.name,
    total_stake.uec_amount
   FROM total_stake
UNION ALL
 SELECT total_liquidity.name,
    total_liquidity.uec_amount
   FROM total_liquidity;