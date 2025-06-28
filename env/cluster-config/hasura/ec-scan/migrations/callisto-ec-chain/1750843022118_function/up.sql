CREATE OR REPLACE FUNCTION public.balance_states_coins_to_text(balance_states_row balance_states)
 RETURNS json
 LANGUAGE sql
 STABLE
AS $function$
	select
	json_agg(json_build_object(
        'denom',
	coin.denom,
	'amount',
	coin.amount::text
    )) as json_result
from
	unnest( balance_states_row.coins )as coin;

$function$
;
