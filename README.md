# README

## START

1. 运行 env/deploy.sh，部署压测环境

2. 手动执行 data/gen/init.sql、data/gen/gen_data.sql，构造压测数据

3. 将构造的地址、区块、交易、验证人等关键数据导出到 data 目录

4. 运行 run.sh（全量接口测试），或者使用以下 locust 指令对接口单独进行测试

```
locust -f test_http.py --tag [待压测接口 tag] --headless -u 20 -r 5 -t 30 --print-stats -H http://127.0.0.1:8000
```
