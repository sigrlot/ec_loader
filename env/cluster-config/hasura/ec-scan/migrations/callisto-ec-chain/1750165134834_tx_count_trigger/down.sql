-- 该脚本用于删除在Callisto ME Hub中添加的区块和交易统计触发器及相关表
-- 删除Block表上的触发器
DROP TRIGGER IF EXISTS tr_block_count ON public.block;

-- 删除Transaction表上的触发器
DROP TRIGGER IF EXISTS tr_transaction_count ON public.transaction;

-- 删除Block表的触发器函数
DROP FUNCTION IF EXISTS public.update_block_count() CASCADE;

-- 删除Transaction表的触发器函数
DROP FUNCTION IF EXISTS public.update_transaction_count() CASCADE;

-- 删除统计表
DROP TABLE IF EXISTS public.block_transaction_count;

