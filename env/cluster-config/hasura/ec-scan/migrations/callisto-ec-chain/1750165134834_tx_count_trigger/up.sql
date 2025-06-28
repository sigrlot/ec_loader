-- 创建hub区块和交易统计表
CREATE TABLE IF NOT EXISTS public.block_transaction_count
(
    id                     int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    total_block_rows       bigint NOT NULL DEFAULT 0,
    total_transaction_rows bigint NOT NULL DEFAULT 0,
    last_updated_block timestamptz,
    last_updated_transaction timestamptz
);

COMMENT ON TABLE public.block_transaction_count IS '区块和交易表联合统计';
COMMENT ON COLUMN public.block_transaction_count.total_block_rows IS '区块表总行数';
COMMENT ON COLUMN public.block_transaction_count.total_transaction_rows IS '交易表总行数';

-- 为Block表创建触发器函数
CREATE OR
    REPLACE FUNCTION public.update_block_count()
    RETURNS TRIGGER AS $$
BEGIN IF TG_OP = 'INSERT' THEN
    UPDATE public.block_transaction_count
    SET total_block_rows   = total_block_rows + 1,
        last_updated_block = NOW();
ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.block_transaction_count
    SET total_block_rows   = total_block_rows - 1,
        last_updated_block = NOW();
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 为Transaction表创建触发器函数
CREATE OR
    REPLACE FUNCTION public.update_transaction_count()
    RETURNS TRIGGER AS $$
BEGIN IF TG_OP = 'INSERT' THEN
    UPDATE public.block_transaction_count
    SET total_transaction_rows   = total_transaction_rows + 1,
        last_updated_transaction = NOW();
ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.block_transaction_count
    SET total_transaction_rows   = total_transaction_rows - 1,
        last_updated_transaction = NOW();
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 初始化统计记录
INSERT INTO public.block_transaction_count (total_block_rows,
                                            total_transaction_rows,
                                            last_updated_block,
                                            last_updated_transaction)
SELECT (SELECT COUNT(*) FROM public.block),
       (SELECT COUNT(*) FROM public."transaction"),
       NOW(),
       NOW()
ON CONFLICT
    (id)
    DO UPDATE SET
                  total_block_rows = EXCLUDED.total_block_rows,
                  total_transaction_rows = EXCLUDED.total_transaction_rows,
                  last_updated_block = EXCLUDED.last_updated_block,
                  last_updated_transaction = EXCLUDED.last_updated_transaction;

-- 为Block表创建触发器
CREATE OR REPLACE TRIGGER tr_block_count
    AFTER INSERT OR DELETE ON public.block
    FOR EACH ROW
EXECUTE FUNCTION public.update_block_count();

-- 为Transaction表创建触发器
CREATE OR REPLACE TRIGGER tr_transaction_count
    AFTER INSERT OR DELETE ON public.transaction
    FOR EACH ROW
EXECUTE FUNCTION public.update_transaction_count();

-- 更新两个统计值
UPDATE public.block_transaction_count
SET total_block_rows         = (SELECT COUNT(*) FROM public.block),
    total_transaction_rows   = (SELECT COUNT(*) FROM public."transaction"),
    last_updated_block       = NOW(),
    last_updated_transaction = NOW();

