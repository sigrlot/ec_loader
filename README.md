# README

## START

1. 运行 env/deploy.sh，部署压测环境

2. 手动执行 data/gen/init.sql、data/gen/gen_data.sql，构造压测数据

3. 运行 run.sh，或者使用以下 locust 指令进行测试

```
locust -f test_http.py --tag [待压测 tag] --headless -u 20 -r 5 -t 30 --print-stats -H http://127.0.0.1:8000
```
